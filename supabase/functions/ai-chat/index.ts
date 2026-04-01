import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { createAIProvider, type ChatMessage } from "../_shared/ai-provider.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface ChatRequest {
  message: string;
  conversation_id: string | null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Verify user auth
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Create authenticated client
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    // Get current user
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { message, conversation_id }: ChatRequest = await req.json();

    if (!message) {
      return new Response(
        JSON.stringify({ error: "message is required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Create or get conversation
    let convId = conversation_id;
    if (!convId) {
      // Create new conversation with first message as title
      const title =
        message.length > 50 ? message.substring(0, 50) + "..." : message;
      const { data: conv, error: convError } = await supabase
        .from("ai_conversations")
        .insert({ user_id: user.id, title })
        .select()
        .single();

      if (convError) throw new Error(`Failed to create conversation: ${convError.message}`);
      convId = conv.id;
    }

    // Save user message
    await supabase.from("ai_messages").insert({
      conversation_id: convId,
      user_id: user.id,
      role: "user",
      content: message,
    });

    // Fetch conversation history
    const { data: history } = await supabase
      .from("ai_messages")
      .select("role, content")
      .eq("conversation_id", convId)
      .order("created_at", { ascending: true })
      .limit(20);

    const chatMessages: ChatMessage[] = (history ?? []).map((m) => ({
      role: m.role as "user" | "assistant",
      content: m.content,
    }));

    // Fetch relevant documents for context
    const documentContext = await buildDocumentContext(supabase, user.id, message);

    // Get AI response stream
    const aiProvider = createAIProvider();
    const stream = await aiProvider.chat(chatMessages, documentContext.context);

    // Collect full response for saving to DB
    const encoder = new TextEncoder();
    const decoder = new TextDecoder();
    let fullResponse = "";

    const transformStream = new TransformStream({
      transform(chunk, controller) {
        const text = decoder.decode(chunk);
        // Parse SSE events and extract text deltas
        const lines = text.split("\n");
        for (const line of lines) {
          if (line.startsWith("data: ")) {
            const data = line.slice(6);
            if (data === "[DONE]") continue;
            try {
              const parsed = JSON.parse(data);
              // Handle Anthropic streaming format
              if (parsed.type === "content_block_delta" && parsed.delta?.text) {
                fullResponse += parsed.delta.text;
                controller.enqueue(
                  encoder.encode(`data: ${JSON.stringify({ text: parsed.delta.text })}\n\n`)
                );
              }
              // Handle OpenAI streaming format
              if (parsed.choices?.[0]?.delta?.content) {
                const content = parsed.choices[0].delta.content;
                fullResponse += content;
                controller.enqueue(
                  encoder.encode(`data: ${JSON.stringify({ text: content })}\n\n`)
                );
              }
            } catch {
              // Skip unparseable lines
            }
          }
        }
      },
      async flush(controller) {
        // Save assistant response to DB
        if (fullResponse) {
          await supabase.from("ai_messages").insert({
            conversation_id: convId,
            user_id: user.id,
            role: "assistant",
            content: fullResponse,
            referenced_docs: documentContext.docIds,
          });

          // Update conversation timestamp
          await supabase
            .from("ai_conversations")
            .update({ updated_at: new Date().toISOString() })
            .eq("id", convId);
        }

        // Send final event with conversation_id
        controller.enqueue(
          encoder.encode(
            `data: ${JSON.stringify({ done: true, conversation_id: convId })}\n\n`
          )
        );
      },
    });

    const responseStream = stream.pipeThrough(transformStream);

    return new Response(responseStream, {
      headers: {
        ...corsHeaders,
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        Connection: "keep-alive",
      },
    });
  } catch (error) {
    console.error("ai-chat error:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

// Build document context for the AI based on the user's question
async function buildDocumentContext(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  question: string
): Promise<{ context: string; docIds: string[] }> {
  // Fetch user's documents with AI data
  const { data: docs } = await supabase
    .from("documents")
    .select("id, title, category, ai_summary, ai_extracted, provider_name, document_date, tags")
    .eq("user_id", userId)
    .eq("status", "ready")
    .order("document_date", { ascending: false, nullsFirst: false })
    .limit(10);

  if (!docs || docs.length === 0) {
    return { context: "No health documents available.", docIds: [] };
  }

  const docIds = docs.map((d) => d.id);
  const contextParts = docs.map((doc) => {
    let entry = `Document: ${doc.title}`;
    if (doc.category) entry += ` | Category: ${doc.category}`;
    if (doc.provider_name) entry += ` | Provider: ${doc.provider_name}`;
    if (doc.document_date) entry += ` | Date: ${doc.document_date}`;
    if (doc.tags?.length) entry += ` | Tags: ${doc.tags.join(", ")}`;
    if (doc.ai_summary) entry += `\nSummary: ${doc.ai_summary}`;
    if (doc.ai_extracted?.key_values) {
      const kvs = doc.ai_extracted.key_values
        .map(
          (kv: Record<string, string>) =>
            `${kv.name}: ${kv.value}${kv.unit ? " " + kv.unit : ""}`
        )
        .join(", ");
      entry += `\nKey Values: ${kvs}`;
    }
    return entry;
  });

  return {
    context: contextParts.join("\n\n---\n\n"),
    docIds,
  };
}
