#!/bin/bash
# Script to push to GitHub repository
# Run this after creating the repository on GitHub

set -e

cd /Users/sashab/SHome/HAssistant

echo "🚀 Pushing to GitHub repository: home-assistant"
echo ""

# Check if remote is configured
if ! git remote get-url origin > /dev/null 2>&1; then
    echo "❌ Remote 'origin' not configured"
    exit 1
fi

echo "📦 Remote configured: $(git remote get-url origin)"
echo ""

# Check if repository exists on GitHub
echo "🔍 Checking if repository exists..."
if git ls-remote origin > /dev/null 2>&1; then
    echo "✅ Repository exists on GitHub"
    echo ""
    echo "📤 Pushing to GitHub..."
    git push -u origin main
    echo ""
    echo "✅ Successfully pushed to GitHub!"
    echo ""
    echo "Repository URL: https://github.com/sasha-barshay/home-assistant"
else
    echo "❌ Repository not found on GitHub"
    echo ""
    echo "Please create the repository first:"
    echo "1. Go to: https://github.com/new"
    echo "2. Repository name: home-assistant"
    echo "3. Select: Private"
    echo "4. DO NOT initialize with README"
    echo "5. Click 'Create repository'"
    echo ""
    echo "Then run this script again: ./push_to_github.sh"
    exit 1
fi

