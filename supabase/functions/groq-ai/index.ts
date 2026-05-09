const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type ChatMessage = {
  role: "system" | "user" | "assistant";
  content: string;
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (request.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    const groqApiKey = Deno.env.get("GROQ_API_KEY");
    if (!groqApiKey) {
      return json({ error: "GROQ_API_KEY secret is not configured" }, 500);
    }

    const body = await request.json();
    const models = normalizeModels(body.models);
    const messages = normalizeMessages(body.messages);
    const temperature = numberOr(body.temperature, 0.5);
    const maxTokens = Math.min(numberOr(body.max_tokens, 900), 1800);

    let lastError = "unknown error";
    for (const model of models) {
      const response = await fetch(
        "https://api.groq.com/openai/v1/chat/completions",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${groqApiKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            model,
            messages,
            temperature,
            max_tokens: maxTokens,
          }),
        },
      );

      const responseText = await response.text();
      if (!response.ok) {
        lastError = `Groq ${response.status}: ${responseText}`;
        continue;
      }

      const data = JSON.parse(responseText);
      const content = data?.choices?.[0]?.message?.content ?? "";
      return json({ content, model });
    }

    return json({ error: lastError }, 502);
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : `${error}` }, 500);
  }
});

function normalizeModels(value: unknown): string[] {
  if (Array.isArray(value)) {
    const models = value.filter((item) => typeof item === "string");
    if (models.length > 0) return models;
  }
  return [
    "openai/gpt-oss-120b",
    "llama-3.3-70b-versatile",
    "llama-3.1-8b-instant",
  ];
}

function normalizeMessages(value: unknown): ChatMessage[] {
  if (!Array.isArray(value)) throw new Error("messages must be an array");
  return value.map((item) => {
    if (
      typeof item !== "object" ||
      item === null ||
      !("role" in item) ||
      !("content" in item)
    ) {
      throw new Error("invalid chat message");
    }
    const role = String((item as Record<string, unknown>).role);
    const content = String((item as Record<string, unknown>).content);
    if (!["system", "user", "assistant"].includes(role)) {
      throw new Error(`unsupported role ${role}`);
    }
    return { role: role as ChatMessage["role"], content };
  });
}

function numberOr(value: unknown, fallback: number): number {
  return typeof value === "number" && Number.isFinite(value) ? value : fallback;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
