#!/bin/bash
touch robots.txt
echo "
User-agent: GPTBot
Disallow: /

User-agent: CCbot
Disallow: /

User-agent: anthropic-ai
Disallow: /

User-agent: Claude-Web
Disallow: /

User-agent: Google-Extended
Disallow: /
" >> robots.txt
