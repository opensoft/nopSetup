# Clone Script Pattern Learning Algorithm Plan

## Problem Analysis

The current clone script assumes all plugins follow the pattern `Nop.Plugin.Opensoft.{name}`, but this is not always correct. For example:
- Failed: `Nop.Plugin.Opensoft.ProductAttribute` (repository doesn't exist)
- Need: Dynamic pattern discovery and learning

## Current State

```bash
# Current hardcoded pattern
REPO_SLUG="Nop.Plugin.Opensoft.$REPO_NAME"
```

## Proposed Solution: Multi-Pattern Learning System

### 1. Pattern Discovery System

Create a comprehensive list of known NopCommerce plugin patterns:

```bash
# Common NopCommerce plugin patterns
PLUGIN_PATTERNS=(
    "Nop.Plugin.Opensoft.{name}"           # Current default
    "Nop.Plugin.{name}"                    # Direct plugin name
    "Nop.Plugin.Misc.{name}"               # Miscellaneous plugins
    "Nop.Plugin.Widgets.{name}"            # Widget plugins
    "Nop.Plugin.Payments.{name}"           # Payment plugins
    "Nop.Plugin.Shipping.{name}"           # Shipping plugins
    "Nop.Plugin.Tax.{name}"                # Tax plugins
    "Nop.Plugin.ExternalAuth.{name}"       # External authentication
    "Nop.Plugin.DiscountRules.{name}"      # Discount rules
    "Nop.Plugin.MultiFactorAuth.{name}"    # Multi-factor authentication
    "Nop.Plugin.Pickup.{name}"             # Pickup plugins
    "Nop.Plugin.Api.{name}"                # API plugins
)
```

### 2. Pattern Cache System

Implement a learning cache that remembers successful patterns:

```bash
# Cache file location
PATTERN_CACHE_FILE="$HOME/.clone_pattern_cache"

# Cache format: plugin_name|successful_pattern|timestamp
# Example:
# ProductAttribute|Nop.Plugin.Misc.ProductAttribute|2025-06-03
# PayPal|Nop.Plugin.Payments.PayPal|2025-06-03
```

### 3. Repository Existence Checking

Add git remote validation before attempting full clone:

```bash
# Function to check if repository exists
check_repository_exists() {
    local repo_url="$1"
    git ls-remote "$repo_url" &>/dev/null
    return $?
}
```

### 4. Pattern Learning Algorithm

```bash
# Algorithm flow:
1. Check cache for known successful pattern
2. If cached, use cached pattern
3. If not cached, try all patterns in order of likelihood
4. For each pattern:
   a. Check if repository exists (git ls-remote)
   b. If exists, cache the pattern and proceed
   c. If not, try next pattern
5. If no patterns work, provide manual override option
6. Update cache with successful patterns
```

### 5. Enhanced User Interface

Add options for manual pattern specification and pattern discovery:

```bash
# New command line options
clone --pattern "Nop.Plugin.Misc.{name}" ProductAttribute
clone --discover ProductAttribute  # Try all patterns and show results
clone --list-patterns              # Show all known patterns
clone --clear-cache               # Clear pattern cache
```

### 6. Intelligent Pattern Prioritization

Prioritize patterns based on:
- Historical success rate
- Plugin name characteristics (e.g., "PayPal" likely uses Payments pattern)
- Recently successful patterns

### 7. Fallback Strategies

```bash
# Fallback options when no patterns work:
1. Search DevOps for similar repository names
2. Prompt user for manual repository URL
3. Show suggestions based on partial matches
4. Allow pattern learning from successful manual entries
```

## Implementation Plan

### Phase 1: Core Pattern System (2-3 hours)
1. ✅ Define pattern array
2. ✅ Implement pattern substitution function
3. ✅ Add repository existence checking
4. ✅ Create basic pattern trying loop

### Phase 2: Caching System (1-2 hours)
1. ✅ Implement pattern cache file operations
2. ✅ Add cache lookup function
3. ✅ Add cache update function
4. ✅ Add cache management commands

### Phase 3: Smart Discovery (2-3 hours)
1. ✅ Implement pattern discovery algorithm
2. ✅ Add intelligent pattern prioritization
3. ✅ Create pattern likelihood scoring
4. ✅ Add plugin name pattern hints

### Phase 4: Enhanced UI (1-2 hours)
1. ✅ Add new command line options
2. ✅ Implement manual pattern override
3. ✅ Add pattern discovery mode
4. ✅ Improve error messages and suggestions

### Phase 5: Advanced Features (2-3 hours)
1. ✅ Add DevOps search functionality
2. ✅ Implement fuzzy matching for suggestions
3. ✅ Add pattern learning from manual entries
4. ✅ Create pattern statistics and reporting

## Detailed Implementation Steps

### Step 1: Pattern Detection Function
```bash
# Function to try multiple patterns for a plugin name
find_repository_pattern() {
    local plugin_name="$1"
    local base_url="$2"

    # Check cache first
    local cached_pattern=$(get_cached_pattern "$plugin_name")
    if [ -n "$cached_pattern" ]; then
        echo "$cached_pattern"
        return 0
    fi

    # Try each pattern
    for pattern in "${PLUGIN_PATTERNS[@]}"; do
        local repo_slug="${pattern//{name}/$plugin_name}"
        local repo_url="$base_url/$repo_slug"

        if check_repository_exists "$repo_url"; then
            cache_pattern "$plugin_name" "$repo_slug"
            echo "$repo_slug"
            return 0
        fi
    done

    return 1
}
```

### Step 2: Cache Management
```bash
# Cache operations
get_cached_pattern() {
    local plugin_name="$1"
    if [ -f "$PATTERN_CACHE_FILE" ]; then
        grep "^$plugin_name|" "$PATTERN_CACHE_FILE" | cut -d'|' -f2 | head -1
    fi
}

cache_pattern() {
    local plugin_name="$1"
    local pattern="$2"
    local timestamp=$(date +%Y-%m-%d)

    # Remove old entry if exists
    if [ -f "$PATTERN_CACHE_FILE" ]; then
        grep -v "^$plugin_name|" "$PATTERN_CACHE_FILE" > "$PATTERN_CACHE_FILE.tmp"
        mv "$PATTERN_CACHE_FILE.tmp" "$PATTERN_CACHE_FILE"
    fi

    # Add new entry
    echo "$plugin_name|$pattern|$timestamp" >> "$PATTERN_CACHE_FILE"
}
```

### Step 3: Intelligent Pattern Hints
```bash
# Function to guess likely patterns based on plugin name
get_pattern_hints() {
    local plugin_name="$1"
    local hints=()

    case "${plugin_name,,}" in
        *payment*|*paypal*|*stripe*|*square*)
            hints+=("Nop.Plugin.Payments.{name}")
            ;;
        *shipping*|*fedex*|*ups*|*usps*)
            hints+=("Nop.Plugin.Shipping.{name}")
            ;;
        *widget*|*slider*|*banner*)
            hints+=("Nop.Plugin.Widgets.{name}")
            ;;
        *tax*|*avalara*|*taxjar*)
            hints+=("Nop.Plugin.Tax.{name}")
            ;;
        *auth*|*facebook*|*google*|*oauth*)
            hints+=("Nop.Plugin.ExternalAuth.{name}")
            ;;
        *)
            hints+=("Nop.Plugin.Misc.{name}" "Nop.Plugin.{name}")
            ;;
    esac

    # Add hints to front of patterns array
    printf '%s\n' "${hints[@]}"
}
```

### Step 4: Enhanced Error Handling
```bash
# Function to provide helpful suggestions when no pattern works
suggest_alternatives() {
    local plugin_name="$1"

    echo "❌ Repository not found with any known pattern."
    echo ""
    echo "🔍 Suggestions:"
    echo "1. Try manual pattern: clone --pattern 'Nop.Plugin.Category.{name}' $plugin_name"
    echo "2. Search repositories: clone --search $plugin_name"
    echo "3. List all patterns: clone --list-patterns"
    echo "4. Use full repository name: clone --full-name 'Exact.Repository.Name'"
    echo ""
    echo "💡 If you know the correct pattern, it will be cached for future use."
}
```

## Testing Strategy

### Test Cases
1. ✅ Known working plugins (cache hit)
2. ✅ Plugins requiring different patterns
3. ✅ Non-existent plugins
4. ✅ Manual pattern override
5. ✅ Cache operations
6. ✅ Pattern discovery mode

### Test Data
```bash
# Test plugins for different patterns
test_plugins=(
    "ProductAttribute:expected_pattern"
    "PayPal:Nop.Plugin.Payments.PayPal"
    "FacebookAuth:Nop.Plugin.ExternalAuth.Facebook"
    "SimpleSlider:Nop.Plugin.Widgets.SimpleSlider"
)
```

## Benefits

1. **Automatic Learning**: Remembers successful patterns
2. **Reduced Errors**: No more failed clones due to wrong patterns
3. **Better UX**: Clear feedback and suggestions
4. **Extensible**: Easy to add new patterns
5. **Intelligent**: Uses plugin name hints for better guessing
6. **Fallback**: Multiple options when automation fails

## Backward Compatibility

- All existing functionality remains unchanged
- Default pattern stays the same for existing workflows
- New features are opt-in via command line flags

## Implementation Priority

1. **High**: Core pattern trying and caching (Phases 1-2)
2. **Medium**: Smart discovery and UI improvements (Phases 3-4)
3. **Low**: Advanced features like DevOps search (Phase 5)

This plan provides a comprehensive solution for handling multiple plugin patterns while maintaining backward compatibility and providing a better user experience.
