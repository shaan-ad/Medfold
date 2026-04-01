import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { createAIProvider } from "../_shared/ai-provider.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { document_id } = await req.json();

    if (!document_id) {
      return new Response(JSON.stringify({ error: "document_id is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Create admin client (bypasses RLS for webhook processing)
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Fetch document record
    const { data: doc, error: docError } = await supabase
      .from("documents")
      .select("*")
      .eq("id", document_id)
      .single();

    if (docError || !doc) {
      throw new Error(`Document not found: ${docError?.message}`);
    }

    // Download file from storage
    const { data: fileData, error: fileError } = await supabase.storage
      .from("documents")
      .download(doc.file_path);

    if (fileError || !fileData) {
      throw new Error(`File download failed: ${fileError?.message}`);
    }

    // Extract text content based on file type
    let textContent: string;
    if (doc.file_type === "pdf") {
      // For PDF: convert to text (basic extraction)
      // In production, use a PDF parsing library or send as base64 to a vision model
      const bytes = await fileData.arrayBuffer();
      const base64 = btoa(String.fromCharCode(...new Uint8Array(bytes)));
      textContent = `[PDF document, base64 encoded - ${base64.substring(0, 1000)}...]`;
    } else {
      // For images: send as base64 for vision model processing
      const bytes = await fileData.arrayBuffer();
      const base64 = btoa(String.fromCharCode(...new Uint8Array(bytes)));
      textContent = `[Image document (${doc.file_type}), base64 encoded - ${base64.substring(0, 1000)}...]`;
    }

    // Send to AI for analysis
    const aiProvider = createAIProvider();
    const analysis = await aiProvider.analyzeDocument(textContent, doc.file_type);

    // Update document with AI results
    const { error: updateError } = await supabase
      .from("documents")
      .update({
        ai_summary: analysis.summary,
        ai_extracted: {
          key_values: analysis.key_values,
          category_suggestion: analysis.category_suggestion,
        },
        category: analysis.category_suggestion,
        provider_name: analysis.provider_name || doc.provider_name,
        document_date: analysis.document_date || doc.document_date,
        status: "ready",
      })
      .eq("id", document_id);

    if (updateError) {
      throw new Error(`Failed to update document: ${updateError.message}`);
    }

    return new Response(
      JSON.stringify({ success: true, document_id }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("analyze-doc error:", error);

    // Try to mark document as error
    try {
      const supabase = createClient(
        Deno.env.get("SUPABASE_URL") ?? "",
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
      );
      const { document_id } = await req.clone().json();
      if (document_id) {
        await supabase
          .from("documents")
          .update({ status: "error" })
          .eq("id", document_id);
      }
    } catch {
      // Ignore cleanup errors
    }

    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
