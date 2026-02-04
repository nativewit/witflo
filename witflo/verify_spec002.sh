#!/bin/bash
# Spec-002 Verification Script
# Run this AFTER completing onboarding (all 3 steps)

WORKSPACE_PATH="$HOME/Library/Containers/com.fyndo.fyndoApp/Data/Documents/FyndoWorkspace"

echo "========================================="
echo "Spec-002 Verification Script"
echo "========================================="
echo ""

echo "1. Checking workspace structure..."
echo "-----------------------------------"
if [ ! -d "$WORKSPACE_PATH" ]; then
    echo "❌ ERROR: Workspace directory not found!"
    echo "   Expected: $WORKSPACE_PATH"
    exit 1
fi

ls -la "$WORKSPACE_PATH"
echo ""

echo "2. Checking workspace metadata..."
echo "-----------------------------------"
if [ ! -f "$WORKSPACE_PATH/.fyndo-workspace.json" ]; then
    echo "❌ ERROR: Workspace metadata not found!"
    exit 1
fi

echo "Content of .fyndo-workspace.json:"
cat "$WORKSPACE_PATH/.fyndo-workspace.json" | python3 -m json.tool
echo ""

# Check for required fields
if grep -q '"salt"' "$WORKSPACE_PATH/.fyndo-workspace.json"; then
    echo "✅ Workspace has salt (CORRECT for spec-002)"
else
    echo "❌ ERROR: Workspace missing salt!"
fi

if grep -q '"kdfParams"' "$WORKSPACE_PATH/.fyndo-workspace.json"; then
    echo "✅ Workspace has kdfParams (CORRECT for spec-002)"
else
    echo "❌ ERROR: Workspace missing kdfParams!"
fi
echo ""

echo "3. Checking keyring file..."
echo "-----------------------------------"
if [ ! -f "$WORKSPACE_PATH/.fyndo-keyring.enc" ]; then
    echo "❌ ERROR: Keyring file not found!"
    exit 1
fi

ls -lh "$WORKSPACE_PATH/.fyndo-keyring.enc"
echo "✅ Keyring file exists"
echo ""

echo "4. Checking vault files..."
echo "-----------------------------------"
if [ ! -d "$WORKSPACE_PATH/vaults" ]; then
    echo "❌ ERROR: Vaults directory not found!"
    exit 1
fi

VAULT_COUNT=$(find "$WORKSPACE_PATH/vaults" -mindepth 1 -maxdepth 1 -type d | wc -l)
echo "Found $VAULT_COUNT vault(s)"
echo ""

if [ "$VAULT_COUNT" -eq 0 ]; then
    echo "⚠️  WARNING: No vaults found. Did onboarding complete?"
    exit 0
fi

echo "Vault directories:"
find "$WORKSPACE_PATH/vaults" -mindepth 1 -maxdepth 1 -type d
echo ""

echo "5. Checking vault headers (CRITICAL CHECK)..."
echo "-----------------------------------"
VAULT_HEADERS=$(find "$WORKSPACE_PATH/vaults" -name "vault.header")

if [ -z "$VAULT_HEADERS" ]; then
    echo "❌ ERROR: No vault.header files found!"
    exit 1
fi

for HEADER in $VAULT_HEADERS; do
    echo "Checking: $HEADER"
    echo "---"
    
    # Show first 30 lines (should be enough to see the JSON structure)
    head -30 "$HEADER"
    echo ""
    
    # CRITICAL CHECKS - v2 format should NOT have these
    if grep -q '"salt"' "$HEADER"; then
        echo "❌ FAIL: Vault header contains 'salt' field!"
        echo "   This indicates v1 format (password-derived keys)"
        echo "   Expected: v2 format (random keys from keyring)"
    else
        echo "✅ PASS: No 'salt' field in vault header (v2 format)"
    fi
    
    if grep -q '"kdfParams"' "$HEADER"; then
        echo "❌ FAIL: Vault header contains 'kdfParams' field!"
        echo "   This indicates v1 format (password-derived keys)"
        echo "   Expected: v2 format (random keys from keyring)"
    else
        echo "✅ PASS: No 'kdfParams' field in vault header (v2 format)"
    fi
    
    echo ""
done

echo "========================================="
echo "Summary"
echo "========================================="
echo ""
echo "Workspace-level (should have salt/kdfParams):"
echo "  - .fyndo-workspace.json: Check output above"
echo "  - .fyndo-keyring.enc: $([ -f "$WORKSPACE_PATH/.fyndo-keyring.enc" ] && echo '✅ Exists' || echo '❌ Missing')"
echo ""
echo "Vault-level (should NOT have salt/kdfParams):"
echo "  - Check vault.header outputs above"
echo ""
echo "If all checks passed:"
echo "  ✅ Spec-002 implementation is CORRECT"
echo "  ✅ Vaults use random keys (not password-derived)"
echo "  ✅ Master password only needed at workspace level"
echo ""
echo "Next steps:"
echo "  1. Test vault access (should open WITHOUT password)"
echo "  2. Test lock/unlock (master password only)"
echo "  3. Test change master password"
