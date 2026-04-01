// AI Provider Abstraction
// Swap providers by changing the AI_PROVIDER env var

export interface AnalysisResult {
  summary: string;
  category_suggestion: string;
  key_values: Record<string, string | number>[];
  provider_name: string | null;
  document_date: string | null;
}

export interface ChatMessage {
  role: "user" | "assistant";
  content: string;
}

export interface AIProvider {
  analyzeDocument(content: string, fileType: string): Promise<AnalysisResult>;
  chat(
    messages: ChatMessage[],
    documentContext: string
  ): Promise<ReadableStream<Uint8Array>>;
}

// Anthropic (Claude) provider
class AnthropicProvider implements AIProvider {
  private apiKey: string;
  private model: string;

  constructor() {
    this.apiKey = Deno.env.get("ANTHROPIC_API_KEY") ?? "";
    this.model = Deno.env.get("AI_MODEL") ?? "claude-sonnet-4-20250514";
  }

  async analyzeDocument(
    content: string,
    fileType: string
  ): Promise<AnalysisResult> {
    const prompt = `Analyze this health document and extract the following information. Return ONLY valid JSON, no other text.

Document type: ${fileType}
Document content:
${content}

Return this exact JSON structure:
{
  "summary": "2-3 sentence summary of the document",
  "category_suggestion": "one of: lab_result, prescription, imaging, insurance, visit_summary, immunization, other",
  "key_values": [{"name": "metric name", "value": "value", "unit": "unit if applicable", "reference_range": "normal range if shown"}],
  "provider_name": "doctor or facility name if found, or null",
  "document_date": "YYYY-MM-DD if found, or null"
}`;

    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": this.apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: this.model,
        max_tokens: 2048,
        messages: [{ role: "user", content: prompt }],
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Anthropic API error: ${response.status} - ${error}`);
    }

    const data = await response.json();
    const text = data.content[0].text;

    // Extract JSON from response (handle markdown code blocks)
    const jsonMatch = text.match(/```json?\s*([\s\S]*?)```/) || [null, text];
    return JSON.parse(jsonMatch[1]!.trim());
  }

  async chat(
    messages: ChatMessage[],
    documentContext: string
  ): Promise<ReadableStream<Uint8Array>> {
    const systemPrompt = `You are a helpful health assistant that analyzes personal health records. You have access to the user's health documents and can answer questions about their health data, identify trends, and provide insights.

Important guidelines:
- Be factual and reference specific documents/values when possible
- Clearly state when you're making observations vs. medical recommendations
- Always recommend consulting a healthcare provider for medical decisions
- Be concise but thorough

The user's health records context:
${documentContext}`;

    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": this.apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: this.model,
        max_tokens: 4096,
        system: systemPrompt,
        messages: messages.map((m) => ({ role: m.role, content: m.content })),
        stream: true,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Anthropic API error: ${response.status} - ${error}`);
    }

    return response.body!;
  }
}

// OpenAI provider
class OpenAIProvider implements AIProvider {
  private apiKey: string;
  private model: string;

  constructor() {
    this.apiKey = Deno.env.get("OPENAI_API_KEY") ?? "";
    this.model = Deno.env.get("AI_MODEL") ?? "gpt-4o";
  }

  async analyzeDocument(
    content: string,
    fileType: string
  ): Promise<AnalysisResult> {
    const prompt = `Analyze this health document and extract the following information. Return ONLY valid JSON, no other text.

Document type: ${fileType}
Document content:
${content}

Return this exact JSON structure:
{
  "summary": "2-3 sentence summary of the document",
  "category_suggestion": "one of: lab_result, prescription, imaging, insurance, visit_summary, immunization, other",
  "key_values": [{"name": "metric name", "value": "value", "unit": "unit if applicable", "reference_range": "normal range if shown"}],
  "provider_name": "doctor or facility name if found, or null",
  "document_date": "YYYY-MM-DD if found, or null"
}`;

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${this.apiKey}`,
      },
      body: JSON.stringify({
        model: this.model,
        messages: [{ role: "user", content: prompt }],
        response_format: { type: "json_object" },
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`OpenAI API error: ${response.status} - ${error}`);
    }

    const data = await response.json();
    return JSON.parse(data.choices[0].message.content);
  }

  async chat(
    messages: ChatMessage[],
    documentContext: string
  ): Promise<ReadableStream<Uint8Array>> {
    const systemPrompt = `You are a helpful health assistant that analyzes personal health records. You have access to the user's health documents and can answer questions about their health data, identify trends, and provide insights.

Important guidelines:
- Be factual and reference specific documents/values when possible
- Clearly state when you're making observations vs. medical recommendations
- Always recommend consulting a healthcare provider for medical decisions
- Be concise but thorough

The user's health records context:
${documentContext}`;

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${this.apiKey}`,
      },
      body: JSON.stringify({
        model: this.model,
        messages: [
          { role: "system", content: systemPrompt },
          ...messages.map((m) => ({ role: m.role, content: m.content })),
        ],
        stream: true,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`OpenAI API error: ${response.status} - ${error}`);
    }

    return response.body!;
  }
}

// Factory function
export function createAIProvider(): AIProvider {
  const provider = Deno.env.get("AI_PROVIDER") ?? "anthropic";

  switch (provider) {
    case "anthropic":
      return new AnthropicProvider();
    case "openai":
      return new OpenAIProvider();
    default:
      throw new Error(`Unknown AI provider: ${provider}`);
  }
}
