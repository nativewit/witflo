# Manual Flow Test - Complete User Journey

## Objective
Test the complete user flow from onboarding to creating notebooks and notes.

## Prerequisites
- App is running on macOS
- VM Service URI: `ws://127.0.0.1:55228/C3BLkI2Kv18=/ws`

## Test Steps

### Step 1: Check Current State
**Look at the app window and identify which screen you're on:**

- [ ] Welcome screen (has "Get Started" button) → Need onboarding
- [ ] Lock screen (has password input) → Need to unlock
- [ ] Vault selection screen (has "Create Vault" button) → Need to create vault
- [ ] Home screen (has notebooks list) → Ready to proceed

### Step 2: Complete Onboarding (if needed)

**If on Welcome Screen:**
1. [ ] Click "Get Started" button (`btn_get_started`)
2. [ ] Choose workspace location (Desktop or default)
3. [ ] Click "Next" (`btn_onboarding_next`)
4. [ ] Enter master password in both fields
5. [ ] Click "Next" (`btn_onboarding_next`)
6. [ ] Enter vault name (e.g., "My Vault")
7. [ ] Click "Finish" (`btn_onboarding_next`)

**If on Lock Screen:**
1. [ ] Enter master password
2. [ ] Click "Unlock Workspace" (`btn_unlock_workspace`)

**If on Vault Selection:**
1. [ ] Click "Create Vault" button (`btn_vault_create` or `btn_vault_create_empty`)
2. [ ] Enter vault name: "Test Vault" (`input_vault_name_create`)
3. [ ] Click "Create Vault" (`btn_vault_create_confirm`)
4. [ ] Select the vault to enter home screen

### Step 3: Create First Notebook
**Keys to use:**
- Create button: `btn_notebook_create_header`
- Name input: `input_notebook_name`
- Confirm button: `btn_notebook_create_confirm`

**Steps:**
1. [ ] Click "+ New Notebook" button in header
2. [ ] Enter name: "First Notebook"
3. [ ] (Optional) Enter description: "My first test notebook"
4. [ ] Click "Create Notebook"
5. [ ] Verify "First Notebook" appears in sidebar
6. [ ] Verify notebook view opens with empty notes list

### Step 4: Create Note in First Notebook
**Keys to use:**
- Create note button: `btn_note_create`
- Title input: `input_note_title`

**Steps:**
1. [ ] Click "+ New Note" button in app bar
2. [ ] Enter title: "First Note"
3. [ ] (Optional) Add some content in the note
4. [ ] Verify note appears in notes list on the left
5. [ ] Verify note is selected and open in editor

### Step 5: Go Back to Home
**Key to use: `btn_back_to_notes` (if on mobile layout)**

**Steps:**
1. [ ] Note should still be visible in the 3-panel layout
2. [ ] Verify note list shows "First Note"
3. [ ] Keep note editor open

### Step 6: Create Second Notebook
**Keys to use:**
- Create button: `btn_notebook_create_header`
- Name input: `input_notebook_name`
- Confirm button: `btn_notebook_create_confirm`

**Steps:**
1. [ ] Click "+ New Notebook" button in header again
2. [ ] Enter name: "Second Notebook"
3. [ ] (Optional) Enter description: "My second test notebook"
4. [ ] Click "Create Notebook"
5. [ ] Verify "Second Notebook" appears in sidebar
6. [ ] Verify automatically switches to "Second Notebook" view
7. [ ] Verify notes list is empty for new notebook

### Step 7: Create Note in Second Notebook
**Keys to use:**
- Create note button: `btn_note_create`
- Title input: `input_note_title`

**Steps:**
1. [ ] Click "+ New Note" button in app bar
2. [ ] Enter title: "Second Note"
3. [ ] (Optional) Add some content
4. [ ] Verify note appears in notes list
5. [ ] Verify note is selected and open in editor

### Step 8: Go Back to First Notebook and Leave Note Open
**Key to use: `notebook_item_<id>` (dynamic based on notebook ID)**

**Steps:**
1. [ ] Look at sidebar on the left
2. [ ] Find "First Notebook" in the notebooks list
3. [ ] Click on "First Notebook" item
4. [ ] Verify switches to "First Notebook" view
5. [ ] Verify notes list shows "First Note"
6. [ ] Click on "First Note" in the notes list (`note_item_<id>`)
7. [ ] Verify note opens in editor on the right
8. [ ] **Leave this note open** - Final state achieved! ✅

## Final State Verification

### Expected UI State:
```
┌─────────────────────────────────────────────────────────────┐
│ Fyndo                                          [Search] [...] │
├──────────┬──────────────┬─────────────────────────────────────┤
│ Sidebar  │ Notes List   │ Note Editor                         │
│          │              │                                     │
│ All Notes│ First Note ● │ First Note                          │
│ Pinned   │              │ ─────────────────                   │
│ Archived │              │                                     │
│          │              │ [Note content here...]              │
│ Notebooks│              │                                     │
│ ─────────│              │                                     │
│ First  ● │              │                                     │
│ Notebook │              │                                     │
│          │              │                                     │
│ Second   │              │                                     │
│ Notebook │              │                                     │
│          │              │                                     │
│ + New    │              │                                     │
└──────────┴──────────────┴─────────────────────────────────────┘
```

### Verification Checklist:
- [ ] Sidebar shows 2 notebooks: "First Notebook" and "Second Notebook"
- [ ] "First Notebook" is selected (highlighted)
- [ ] Notes list shows "First Note"
- [ ] "First Note" is selected in the notes list
- [ ] Note editor displays "First Note" content
- [ ] Database should contain:
  - 1 vault
  - 2 notebooks
  - 2 notes (one in each notebook)

## Testing with Marionette (Optional)

To verify all keys are working, you can check interactive elements:

```bash
cd fyndo
fvm dart test_marionette_full.dart ws://127.0.0.1:55228/C3BLkI2Kv18=/ws
```

This will:
- Take screenshots at each stage
- List all interactive elements with their keys
- Verify that all 78+ keys are detectable

## Database Verification

Check the workspace directory for:
```
~/Documents/Fyndo/
├── workspace.json
├── keyring.json
└── vaults/
    └── <vault-id>/
        └── notebooks/
            ├── <first-notebook-id>/
            │   └── notes/
            │       └── <first-note-id>.md
            └── <second-notebook-id>/
                └── notes/
                    └── <second-note-id>.md
```

## Success Criteria

✅ All steps completed without errors
✅ Both notebooks visible in sidebar  
✅ Both notes created successfully
✅ Can navigate between notebooks
✅ First note is open in editor
✅ All widget keys responded correctly
✅ No UI freezes or crashes

---

**Test Date:** ___________  
**Tester:** ___________  
**Result:** [ ] PASS [ ] FAIL  
**Notes:** ___________________________________________
