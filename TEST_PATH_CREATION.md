# Challenge Path Creation - Testing Guide

## Feature Summary
Users can now create custom challenge paths by selecting games and difficulties through a 3-step form.

## Manual Testing Steps

### Test 1: Navigate to Paths Tab
1. Open the app (should already be running at http://localhost:xxxx)
2. If not logged in, log in with your credentials
3. Look at the bottom navigation bar
4. Click the **"Paths"** tab (map icon)
5. You should see the **"Create Path"** FAB button (blue circle with +)

**Expected result:** Paths tab displays with empty state or existing paths

---

### Test 2: Start Creating a Path
1. Click the **"Create Path"** FAB button
2. You should see **Step 1 of 3: Path Information**

**Expected result:** Form appears with:
- "Create Your Challenge Path" heading
- Path Name field (required, 3-50 chars)
- Description field (optional, max 200 chars)
- Public/Private toggle
- "Next" button (disabled until valid)

---

### Test 3: Fill Step 1 - Path Information
1. Enter path name: "My Logic Challenge" (3+ characters)
2. Enter description: "Test your puzzle-solving skills" (optional)
3. Toggle "Make it public?" to ON or OFF
4. Verify **"Next"** button becomes enabled
5. Click **"Next"**

**Expected result:** 
- Path name must be 3-50 characters (show error if not)
- Button enables when valid
- Step 2 appears

---

### Test 4: Fill Step 2 - Game Selection
You should now see **Step 2 of 3: Choose which games to include**

**Part A: Set Default Difficulty**
1. See three difficulty buttons: Easy, Medium, Hard
2. Click **"Hard"** to set global difficulty
3. Verify the button is now highlighted/selected

**Part B: Add Games**
1. You'll see a dropdown with game types
2. Select **"Kakuro"** from the dropdown
3. Below that, you'll see difficulty chips defaulting to "Hard"
4. Click **"Add Game"**
5. You should see "Kakuro (Hard)" appear in the list below

**Part C: Add More Games**
1. Change dropdown to **"Nonogram"**
2. Override difficulty to **"Easy"** by clicking the Easy chip
3. Click **"Add Game"**
4. You should see both games in the list:
   - Kakuro (Hard)
   - Nonogram (Easy)

**Part D: Navigation**
1. Verify the **"Next"** button is enabled (have at least 1 game)
2. Try clicking **"Back"** - should return to Step 1
3. Try clicking **"Next"** - should go to Step 3

**Expected result:**
- Games display with correct types and difficulties
- Per-game difficulty override works
- Min 1 game validation works
- Back/Next navigation works

---

### Test 5: Review on Step 3 - Confirm
You should see **Step 3 of 3: Confirm and Create**

**Verify Information:**
1. Path summary card shows:
   - Name: "My Logic Challenge"
   - Description: "Test your puzzle-solving skills"
   - Visibility: Public or Private (with icon)
2. Games section shows:
   - Number of games selected
   - List of all games with correct order (#1, #2, etc.)
   - Each game shows type, difficulty, and icon

**Expected result:**
- All selected information is displayed correctly
- Games appear in the order they were added
- Icons and colors are visible

---

### Test 6: Create the Path
1. Click **"Create Challenge"** button
2. You should see a loading spinner
3. After creation succeeds, you should be redirected to the path detail screen

**Expected result:**
- Path is created in the database
- User is redirected to `/paths/{pathId}`
- New path appears in Paths tab list

---

### Test 7: Error Handling
**Test invalid inputs:**

1. **Empty path name:**
   - Try clicking Next on Step 1 with empty name
   - Should show error and disable Next button

2. **Short path name:**
   - Enter only "AB" (less than 3 chars)
   - Should show error and disable Next button

3. **No games selected:**
   - On Step 2, click Next without adding any games
   - Should be disabled or show error

4. **Network error:**
   - While creating, simulate a network error (server down)
   - Should show error snackbar with error message

---

## Validation Checklist

### Frontend Form Validation
- [ ] Path name: required, 3-50 characters
- [ ] Description: optional, max 200 characters
- [ ] Visibility: toggle works (public/private)
- [ ] Global difficulty: can select easy/medium/hard
- [ ] Per-game difficulty: can override global setting
- [ ] Game selection: shows all 4 game types
- [ ] Min/max games: requires 1, max 10
- [ ] Navigation: back/next work at each step
- [ ] Step indicators: clearly show which step user is on

### API Integration
- [ ] Backend `/puzzles/random/{type}?difficulty={difficulty}` works
- [ ] Backend `POST /paths/` accepts puzzle list
- [ ] Backend returns created path with ID
- [ ] Frontend redirects to `/paths/{pathId}` after creation

### Database
- [ ] Path created with correct name, description, is_public
- [ ] Path linked to correct user (creator_id)
- [ ] PathPuzzle entries created for each game
- [ ] PathPuzzle entries have correct puzzle_id and order

---

## Debugging Tips

1. **Check backend logs** for errors during puzzle fetching
2. **Check browser console** (F12) for JavaScript errors
3. **Check network tab** to see API requests and responses
4. **Verify database** has puzzles: `SELECT * FROM puzzles;`
5. **Test API directly** with curl:
   ```bash
   curl "http://192.168.101.18:8000/puzzles/random/kakuro?difficulty=easy"
   ```

---

## Known Issues & Notes

- Path detail screen is a placeholder (will be implemented separately)
- Drag-to-reorder games is not yet implemented (nice-to-have)
- No image/file uploads for puzzles (puzzles stored as JSON)
- Cannot edit paths after creation (will be future feature)

---

## Success Criteria

✅ User can create a complete path with multiple games  
✅ Each game can have its own difficulty level  
✅ Path appears in user's paths list on Paths tab  
✅ Form validation works and guides user  
✅ Error messages are clear and helpful
