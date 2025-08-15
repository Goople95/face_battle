# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Face Battle (表情博弈) is a Flutter-based Liar's Dice game where players compete against AI opponents with dynamic facial expressions and personalities. The game implements sophisticated AI behavior through both local algorithms and cloud-based Gemini AI integration.

## Development Commands

### Essential Flutter Commands
```bash
# Dependencies
flutter pub get                    # Install/update dependencies

# Run the app
flutter run                       # Debug mode (default)
flutter run --release             # Release mode
flutter run --profile             # Profile mode

# Build
flutter build apk                 # Android APK
flutter build appbundle           # Android App Bundle  
flutter build ios                 # iOS app
flutter build windows             # Windows desktop

# Code quality
flutter analyze                   # Run static analysis
dart format .                     # Format all Dart files
dart fix --apply                  # Apply automated fixes
```
# Project Context
Preferred working language: zh

### Project-Specific Commands
```powershell
# Enhanced logging with filtering (Windows PowerShell)
.\flutter_run_log.ps1             # Debug mode with filtered logs
.\flutter_run_log.ps1 -Release    # Release mode with logs
.\flutter_run_log.ps1 -NoFilter   # Show all logs including system
.\flutter_run_log.ps1 -Verbose    # Verbose Flutter output
```

## Architecture Overview

### Core Game Loop
The game implements a turn-based Liar's Dice with the following flow:
1. **Roll Phase**: Both players roll 5 dice secretly
2. **Bidding Phase**: Players alternate making increasingly higher bids
3. **Challenge Phase**: When a bid is challenged, dice are revealed
4. **Resolution**: Loser drinks, game state updates, drinking effects apply

### AI System Architecture

The AI operates on two levels:

**1. Decision Engine** (`lib/services/`)
- **Primary**: `gemini_service.dart` - Cloud-based Gemini AI for intelligent decisions
- **Fallback**: `ai_service.dart` - Local probability-based algorithm when API unavailable
- Automatic fallback when API fails or `useRealAI = false` in config

**2. Personality System** (`lib/models/ai_personality.dart`)
Each AI character has distinct behavioral parameters:
- `bluffRatio`: Tendency to make false bids (0-1)
- `challengeThreshold`: When to challenge opponent bids (0-1)  
- `riskAppetite`: Willingness to make aggressive bids (0-1)
- `tellExposure`: Probability of showing emotional tells (0-1)
- `reverseActingProb`: Chance of showing misleading emotions (0-1)

### Expression System

The game uses three methods for AI facial expressions:

1. **Video Expressions** (`lib/widgets/ai_video_avatar.dart`)
   - MP4 videos for 10 emotional states per character
   - Located in `assets/people/[character]/videos/`
   - States: happy, angry, confident, nervous, etc.

2. **Custom Painted Faces** (`lib/widgets/animated_ai_face.dart`)
   - Algorithmic face drawing using Flutter Canvas
   - Real-time emotion interpolation using valence/arousal model
   - Smooth transitions between emotional states

3. **Rive Animations** (Planned upgrade)
   - Integration ready but not yet implemented
   - Will replace custom painting for smoother animations

### State Management

**Game State** (`lib/models/game_state.dart`)
- Player and AI dice values
- Current bid tracking
- Round history
- Win/loss tracking

**Drinking System** (`lib/models/drinking_state.dart`)
- Tracks alcohol consumption (0-6 drinks)
- Implements sobering timer (10 minutes per drink)
- Blocks gameplay at 3+ drinks until sober

## API Configuration

### Gemini AI Setup
1. Obtain API key from https://aistudio.google.com/
2. Configure in `lib/config/api_config.dart`:
   - Replace `YOUR_API_KEY_HERE` with actual key
   - Set `useRealAI = true` to enable cloud AI
   - Set `useRealAI = false` for local-only AI

**Important**: Never commit real API keys. The config file should be added to .gitignore.

## Key Game Mechanics

### Dice Rules
- Each player has 5 dice (1-6)
- **1s are wildcards** by default (count as any number)
- Once someone bids on 1s, they lose wildcard status for that round
- Bids must increase in quantity or dice value each turn

### Bidding Logic
Valid bid progressions:
- Same dice, higher quantity: `3×4 → 4×4`
- Higher dice, same/more quantity: `3×4 → 3×5` or `3×4 → 4×5`  
- Lower dice, must increase quantity: `3×5 → 4×2`

### Challenge Resolution
When a bid is challenged:
1. All dice revealed
2. Count actual quantity including wildcards
3. If actual ≥ bid: challenger loses
4. If actual < bid: bidder loses

## Logging and Debugging

The project includes comprehensive logging:
- **LoggerUtils** (`lib/utils/logger_utils.dart`): Structured logging with levels
- **PowerShell script** filters system noise from Flutter logs
- Logs saved to `logs/` directory with timestamps
- Debug mode shows detailed AI decision reasoning

## Current Limitations

- No unit tests implemented
- Rive animations prepared but not integrated
- Video expressions may have loading delays on first play
- AI API calls have 60/minute rate limit (free tier)