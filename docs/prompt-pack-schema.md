# Prompt Pack Schema

Each prompt pack should be JSON-serializable and easy for another agent to use.

```json
{
  "source": {
    "repo": "owner/name",
    "url": "https://github.com/owner/name",
    "default_branch": "main",
    "commit_sha": "abc123",
    "license_key": "mit",
    "captured_at": "2026-04-25T00:00:00Z"
  },
  "trend": {
    "window": "7d",
    "score": 123,
    "stars_now": 5000,
    "star_delta_24h": 300,
    "star_delta_7d": 1200,
    "fork_delta_7d": 80
  },
  "summary": "What the project does and who it is for.",
  "architecture": {
    "runtime": "Node.js",
    "frameworks": ["Express"],
    "modules": [
      {
        "name": "api",
        "responsibility": "HTTP routes and request validation"
      }
    ]
  },
  "file_map": [
    {
      "path": "src/index.ts",
      "purpose": "Application entry point"
    }
  ],
  "behavior": [
    "CLI/API/UI behavior that must be reproduced"
  ],
  "implementation_prompt": "Prompt for rebuilding the project from scratch.",
  "test_prompt": "Prompt for generating and running verification tests.",
  "known_gaps": [
    "Unverified behavior or intentionally omitted details"
  ],
  "verification": {
    "status": "not-run",
    "commands": [],
    "notes": ""
  }
}
```

## Required Attribution

Every published prompt pack must include:

- original repository URL
- owner/name
- license key
- default branch commit SHA
- capture timestamp

## Generation Guidance

The prompt pack should describe the project at the level of behavior and
architecture. Do not paste large source files. Small signatures, command names,
route names, and configuration keys are acceptable when needed for clarity.
