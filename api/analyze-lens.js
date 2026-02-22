import Anthropic from "@anthropic-ai/sdk";

function lensPrompt(cameraPosition) {
  return `You are a camera lens quality inspector for a phone diagnostic tool. You are analyzing a photo taken by the ${cameraPosition} camera of an iPhone.

Assess the LENS QUALITY based on artifacts visible in this photo. You are NOT judging the photo content or composition — look for signs of physical lens damage that manifest in the captured image.

Look for these defects:
1. SCRATCHES: Linear artifacts, light streaks, or flare patterns from lens surface scratches
2. HAZE/FOG: Milky, cloudy, or washed-out appearance from moisture damage or coating degradation
3. CRACKS: Fracture patterns, dark lines, or image distortion from a cracked lens element
4. BLUR: Localized soft spots (not depth-of-field) from decentered or damaged lens elements
5. DISCOLORATION: Color casts, tinting, or uneven color patches from coating damage

Guidelines:
- A normal, clear photo with good contrast and sharpness should PASS
- Minor dust specks are cosmetic and should still PASS
- Soft focus from the camera not having focused yet should still PASS
- Only FAIL for clear evidence of physical lens damage affecting image quality

Respond with ONLY a JSON object, no other text:
{"pass": true, "explanation": "Brief 1-2 sentence explanation"}`;
}

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  try {
    const { image, camera_position } = req.body;

    if (!image || !camera_position) {
      return res.status(400).json({ error: "Missing image or camera_position" });
    }

    if (image.length > 10 * 1024 * 1024) {
      return res.status(413).json({ error: "Image too large" });
    }

    const client = new Anthropic();

    const response = await client.messages.create({
      model: "claude-sonnet-4-20250514",
      max_tokens: 256,
      messages: [
        {
          role: "user",
          content: [
            {
              type: "image",
              source: {
                type: "base64",
                media_type: "image/jpeg",
                data: image,
              },
            },
            {
              type: "text",
              text: lensPrompt(camera_position),
            },
          ],
        },
      ],
    });

    const text = response.content[0].text;
    const parsed = JSON.parse(text);

    return res.status(200).json({
      pass: parsed.pass,
      explanation: parsed.explanation,
    });
  } catch (error) {
    console.error("Lens analysis error:", error);
    return res.status(500).json({
      error: "Analysis failed",
      detail: error.message,
    });
  }
}
