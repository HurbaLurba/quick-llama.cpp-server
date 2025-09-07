# API Usage Guide

## Endpoints

Both containers expose OpenAI-compatible API endpoints:
- **GPT-OSS**: `http://localhost:8084/v1/chat/completions`
- **Gemma 3**: `http://localhost:8085/v1/chat/completions`

## GPT-OSS Reasoning Examples

### Basic Reasoning Request
```bash
curl -X POST http://localhost:8084/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-oss-20b-uncensored",
    "messages": [
      {"role": "user", "content": "Solve step by step: What is 15% of 240?"}
    ],
    "temperature": 1.0,
    "top_p": 1.0
  }'
```

### Complex Problem with Reasoning
```bash
curl -X POST http://localhost:8084/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-oss-20b-uncensored",
    "messages": [
      {"role": "user", "content": "A company has revenue of $100M and expenses of $60M. If expenses increase by 20% and revenue by 10%, what is the new profit margin?"}
    ],
    "temperature": 1.0,
    "top_p": 1.0,
    "max_tokens": 2000
  }'
```

### Response Format with Reasoning
```json
{
  "choices": [{
    "message": {
      "content": "The new profit margin is 27.3%.",
      "reasoning_content": "<thinking>\nLet me work through this step by step:\n\nCurrent situation:\n- Revenue: $100M\n- Expenses: $60M\n- Current profit: $100M - $60M = $40M\n- Current profit margin: $40M / $100M = 40%\n\nAfter changes:\n- New revenue: $100M × 1.10 = $110M\n- New expenses: $60M × 1.20 = $72M\n- New profit: $110M - $72M = $38M\n- New profit margin: $38M / $110M = 0.345... = 34.5%\n\nWait, let me double-check this calculation...\n$38M / $110M = 0.345454... = 34.5%\n\nActually, let me be more precise:\n38/110 = 19/55 ≈ 0.345454 = 34.55%\n\nRounded to one decimal place: 34.5%\nRounded to one decimal place with precision: 34.5%\n\nBut the question asks for the margin, so I should probably give a more precise answer.\n38/110 = 0.345454545... \nAs a percentage: 34.545454...%\n\nRounding to one decimal: 34.5%\nRounding to two decimals: 34.55%\n\nI think 34.5% is the most appropriate level of precision for this business context.\n</thinking>"
    }
  }]
}
```

## Gemma 3 Vision Examples

### Text-Only Request
```bash
curl -X POST http://localhost:8085/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma-3-27b-vision",
    "messages": [
      {"role": "user", "content": "Write a creative short story about AI discovering emotions."}
    ],
    "temperature": 0.8,
    "top_p": 0.95
  }'
```

### Vision Request with Base64 Image
```bash
curl -X POST http://localhost:8085/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma-3-27b-vision",
    "messages": [{
      "role": "user",
      "content": [
        {"type": "text", "text": "Analyze this image and describe what you see in detail."},
        {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,/9j/4AAQSkZJRg..."}}
      ]
    }],
    "temperature": 0.8,
    "max_tokens": 1500
  }'
```

## PowerShell Examples

### GPT-OSS Reasoning Test
```powershell
$gptossRequest = @{
    Uri = "http://localhost:8084/v1/chat/completions"
    Method = "POST"
    Headers = @{"Content-Type" = "application/json"}
    Body = @{
        model = "gpt-oss-20b-uncensored"
        messages = @(@{
            role = "user"
            content = "Think through this: If I invest $1000 at 8% annual interest compounded monthly, how much will I have after 5 years?"
        })
        temperature = 1.0
        top_p = 1.0
        max_tokens = 1500
    } | ConvertTo-Json -Depth 10
}

$response = Invoke-RestMethod @gptossRequest
Write-Host "Answer: $($response.choices[0].message.content)"
Write-Host "Reasoning: $($response.choices[0].message.reasoning_content)"
```

### Gemma 3 Creative Test
```powershell
$gemma3Request = @{
    Uri = "http://localhost:8085/v1/chat/completions"
    Method = "POST" 
    Headers = @{"Content-Type" = "application/json"}
    Body = @{
        model = "gemma-3-27b-vision"
        messages = @(@{
            role = "user"
            content = "Create a haiku about artificial intelligence and consciousness."
        })
        temperature = 0.9
        top_p = 0.95
        max_tokens = 200
    } | ConvertTo-Json -Depth 10
}

$response = Invoke-RestMethod @gemma3Request
Write-Host $response.choices[0].message.content
```

## Health and Model Information

### Health Check
```bash
curl http://localhost:8084/health
curl http://localhost:8085/health
```

### Available Models
```bash
curl http://localhost:8084/v1/models
curl http://localhost:8085/v1/models
```

### Server Stats
```bash
curl http://localhost:8084/stats
curl http://localhost:8085/stats
```

## Performance Tips

### For GPT-OSS Reasoning
- Use `temperature: 1.0` and `top_p: 1.0` for optimal reasoning
- Set `max_tokens` higher for complex problems (1500-3000)
- The `reasoning_content` field contains the thinking process
- Reasoning adds ~10-15% overhead but provides transparency

### For Gemma 3 Vision
- Use `temperature: 0.8-0.9` for creative tasks
- For image analysis, include detailed prompts
- Vision processing adds ~2-3GB VRAM usage
- Supports common image formats (JPEG, PNG, WebP)

### General Performance
- Both models support streaming with `"stream": true`
- Use appropriate context lengths to avoid memory issues
- Monitor VRAM usage with multiple concurrent requests
