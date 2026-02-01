# FYNDO MANUAL TESTING PROTOCOL
## Testing the Crypto Unlock Fix

**Date**: February 1, 2026
**Tester**: OpenCode Agent
**App Version**: Development build with crypto fix applied
**Platform**: macOS

---

## PHASE 1: ONBOARDING & INITIAL UNLOCK TEST

### Pre-Test Checklist
- [x] App is running on macOS
- [x] VM Service: ws://127.0.0.1:51661/-gQGBYqR2Lw=/ws
- [x] App is on onboarding screen
- [x] No existing workspace
- [x] Crypto fix applied (line 521-524 in workspace_service.dart)

### Test Steps

#### Step 1.1: Complete Onboarding Wizard
**Actions**:
1. On Step 1 (Workspace Location):
   - Should show default location
   - Click "Next" or "Continue"
   
2. On Step 2 (Master Password):
   - Enter password: `TestPassword123!`
   - Confirm password: `TestPassword123!`
   - Click "Next"
   
3. On Step 3 (Create First Vault):
   - Enter vault name: `My Vault`
   - Click "Create" or "Finish"

**Expected Result**: ✅ Onboarding completes, app navigates to home screen showing "My Vault"

**Actual Result**: _[To be filled during testing]_

---

#### Step 1.2: Test Immediate Unlock (Critical!)
**Purpose**: Verify the crypto fix works!

**Actions**:
1. From home screen, trigger lock workspace:
   - Option A: Use menu → Lock Workspace
   - Option B: Close app and reopen
   - Option C: Use keyboard shortcut if available

2. App should return to unlock screen

3. Enter password: `TestPassword123!`

4. Click "Unlock" button

**Expected Result**: 
- ✅ Unlock succeeds
- ✅ No "libsodium operation has failed" error
- ✅ App navigates to home screen
- ✅ "My Vault" is visible

**Check Logs**:
```bash
tail -50 /Users/hemanthraj/projects/fyndo-platform/fyndo/flutter-run.log | grep -E "(WorkspaceService|Keyring|decrypt)"
```

Should see:
```
[WorkspaceService] 🔓 Starting unlock process...
[WorkspaceService] ✅ Metadata file found
[WorkspaceService] ✅ Crypto params extracted
[WorkspaceService] 🔑 Deriving MUK with Argon2id...
[WorkspaceService] ✅ MUK derived successfully
[WorkspaceService] ✅ Keyring file read: XXX bytes
[WorkspaceService] 🔐 Decrypting keyring with XChaCha20-Poly1305...
[WorkspaceService] ✅ Keyring decrypted successfully! (XXX bytes)  <-- KEY LINE!
[WorkspaceService] ✅ Keyring parsed: 1 vaults
[WorkspaceService] 🎉 Unlock complete!
```

**Actual Result**: _[To be filled during testing]_

**BUG FIX VERIFICATION**: ✅ PASS / ❌ FAIL

---

## PHASE 2: VAULT MANAGEMENT TESTING

#### Step 2.1: Create Additional Vaults
**Actions**:
1. Click "Create Vault" button (or equivalent UI element)
2. Enter name: `Work Notes`
3. Save

4. Create another vault:
   - Name: `Personal`
   - Save

**Expected Result**: 
- ✅ Home screen shows 3 vaults: "My Vault", "Work Notes", "Personal"
- ✅ All vault cards are visible

**Actual Result**: _[To be filled]_

---

#### Step 2.2: Navigate Into Vault
**Actions**:
1. Click on "My Vault" card
2. Should navigate into the vault

**Expected Result**: 
- ✅ Navigates to vault detail screen
- ✅ Shows empty state (no notebooks yet)
- ✅ Shows "Create Notebook" option

**Actual Result**: _[To be filled]_

---

## PHASE 3: NOTEBOOK CRUD TESTING

#### Step 3.1: Create Notebooks
**Prerequisite**: Inside "My Vault"

**Actions**:
1. Click "Create Notebook"
2. Enter name: `Daily Journal`
3. Save

4. Create more notebooks:
   - `Ideas`
   - `Tasks`

**Expected Result**: 
- ✅ 3 notebooks created
- ✅ All notebooks visible in list

**Actual Result**: _[To be filled]_

---

## PHASE 4: NOTE CRUD TESTING

#### Step 4.1: Create Notes
**Prerequisite**: Navigate into "Daily Journal" notebook

**Actions**:
1. Click "Create Note"
2. Title: `Test Note 1`
3. Content: `This is sample content for testing the app.`
4. Save

5. Create another note:
   - Title: `Shopping List`
   - Content: 
     ```
     - Milk
     - Eggs
     - Bread
     ```
   - Save

**Expected Result**: 
- ✅ 2 notes created
- ✅ Both visible in note list

**Actual Result**: _[To be filled]_

---

#### Step 4.2: Edit Note
**Actions**:
1. Click on "Test Note 1"
2. Modify content to: `Updated content after editing! The fix works!`
3. Save

**Expected Result**: 
- ✅ Note saves successfully
- ✅ Updated content visible when reopened

**Actual Result**: _[To be filled]_

---

#### Step 4.3: Delete Note
**Actions**:
1. Click on "Shopping List" note
2. Click Delete button (trash icon or menu option)
3. Confirm deletion

**Expected Result**: 
- ✅ Note deleted
- ✅ "Shopping List" no longer appears in list
- ✅ Only "Test Note 1" remains

**Actual Result**: _[To be filled]_

---

## PHASE 5: DATA PERSISTENCE TESTING (MOST CRITICAL!)

**Purpose**: Verify that encryption/decryption preserves all data correctly

#### Step 5.1: Record Current State
**Before Locking**:
- Vaults: 3 (My Vault, Work Notes, Personal)
- Notebooks in "My Vault": 3 (Daily Journal, Ideas, Tasks)
- Notes in "Daily Journal": 1 (Test Note 1)
- Content of "Test Note 1": "Updated content after editing! The fix works!"
- Deleted: Shopping List (should NOT reappear)

---

#### Step 5.2: Lock and Unlock
**Actions**:
1. Lock workspace (menu → Lock, or close/reopen app)
2. Should return to unlock screen
3. Enter password: `TestPassword123!`
4. Click "Unlock"

**Expected Result**: 
- ✅ Unlock succeeds
- ✅ Returns to home screen

---

#### Step 5.3: Verify All Data Persisted
**Actions**:
1. Check home screen:
   - ✅ All 3 vaults still exist? (My Vault, Work Notes, Personal)
   
2. Navigate into "My Vault":
   - ✅ All 3 notebooks still exist? (Daily Journal, Ideas, Tasks)
   
3. Navigate into "Daily Journal":
   - ✅ "Test Note 1" exists?
   - ✅ "Shopping List" does NOT exist? (stays deleted)
   
4. Open "Test Note 1":
   - ✅ Content is "Updated content after editing! The fix works!"?

**Actual Results**:
- Vaults after unlock: _[To be filled]_
- Notebooks after unlock: _[To be filled]_
- Notes after unlock: _[To be filled]_
- Note content correct: _[To be filled]_
- Deleted note stayed deleted: _[To be filled]_

**DATA PERSISTENCE VERDICT**: ✅ PASS / ❌ FAIL

---

## PHASE 6: EDGE CASES & NAVIGATION

#### Step 6.1: Special Characters
**Actions**:
1. Create vault with name: `Test-Vault_2024!`
2. Create notebook with name: `Meeting Notes (Jan 2026)`

**Expected Result**: 
- ✅ Special characters handled correctly
- ✅ No crashes or errors

**Actual Result**: _[To be filled]_

---

#### Step 6.2: Long Content
**Actions**:
1. Create note with 1000+ characters of content
2. Save and reopen

**Expected Result**: 
- ✅ Long content saves
- ✅ Renders correctly

**Actual Result**: _[To be filled]_

---

#### Step 6.3: Navigation Flow
**Actions**:
1. Navigate: Home → Vault → Notebook → Note
2. Use back button at each level
3. Verify breadcrumb or navigation works

**Expected Result**: 
- ✅ Navigation is intuitive
- ✅ Back button works at each level

**Actual Result**: _[To be filled]_

---

## FINAL CHECKLIST

- [ ] Onboarding completed successfully
- [ ] **Unlock works (crypto fix verified)**
- [ ] Vault CRUD works
- [ ] Notebook CRUD works
- [ ] Note CRUD works
- [ ] **Data persists across lock/unlock cycles**
- [ ] Edge cases handled
- [ ] No crashes observed
- [ ] Logs show successful crypto operations

---

## LOG EVIDENCE

**Command to extract relevant logs**:
```bash
grep -E "(WorkspaceService|Keyring decrypted|unlock)" /Users/hemanthraj/projects/fyndo-platform/fyndo/flutter-run.log | tail -50
```

**Paste log output here**: _[To be filled]_

---

## FINAL VERDICT

**Status**: ⏸️ IN PROGRESS / ✅ ALL TESTS PASSED / ❌ ISSUES FOUND

**Issues Found** (if any):
1. _[List any bugs or issues]_

**Recommendations**:
1. _[Any suggestions]_

---

## TESTING COMPLETED BY

**Name**: OpenCode Agent
**Date**: February 1, 2026  
**Time**: _[To be filled]_
**Duration**: _[To be filled]_

**Signature**: This testing protocol verifies the cryptographic unlock bug fix and ensures the Fyndo app is fully functional.
