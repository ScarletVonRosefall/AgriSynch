# Comprehensive Sign-Up: Quick Reference

## What the New Signup Does

**Single-page form that:**
- Collects account info (email, password, account type)
- Collects personal info (full name breakdown)
- Collects contact info (phone)
- Collects location via GPS (not manual text entry)
- Collects bio
- Creates complete user profile immediately

**All in ONE form** instead of signup → profile completion

## User Experience

### Before
1. Sign up (email, password, name)
2. Redirected to verify email
3. After verification → Profile completion page (asking for surname, firstName, phone, bio, location)
4. Complete profile
5. Finally access dashboard

### After  
1. Comprehensive sign-up form (all fields)
   - Tap "Get Location" button → GPS coordinates auto-filled
2. Tap "Complete Registration"
3. Redirected to verify email
4. After verification → Dashboard (profile already complete!)

## Location Feature

### How It Works
- User taps "Get Location" button
- System requests location permission (first time)
- GPS retrieves current position
- Coordinates displayed as: `12.3456, 78.9012`
- Both latitude and longitude saved to Firestore

### Why GPS Instead of Text?
- ✅ Accurate geographic coordinates
- ✅ No typos in location names
- ✅ Ready for distance calculations
- ✅ Enables location-based features

## Code Changes

### File Structure
```
lib/auth/
├── AgriSynchSignUpComprehensive.dart  ← NEW comprehensive form
├── AgriSynchSignUp.dart               ← OLD (still present, no longer used)
├── auth_wrapper.dart
└── ...
```

### Route Update
```dart
// In main.dart routes:
'/signup': (context) => const AgriSynchComprehensiveSignUpPage(),
```

## Form Fields (In Order)

1. **Account Type** - Dropdown (Farmer/Buyer)
2. **Email** - Email input with validation
3. **Password** - Password input (min 6 chars)
4. **Surname** - Text field
5. **First Name** - Text field
6. **Middle Name** - Text field
7. **Nickname** - Text field
8. **Phone Number** - Phone input format
9. **Location** - Read-only field with "Get Location" button
10. **Bio** - Multi-line text field
11. **Terms Checkbox** - Required to proceed

## Firestore Document

When user signs up, this is created in `/users/{uid}`:

```dart
{
  'uid': user.uid,
  'email': 'user@email.com',
  'name': 'Santos, Juan, Dela Cruz',  // Full name concatenated
  'surname': 'Santos',
  'firstName': 'Juan',
  'middleName': 'Dela Cruz',
  'nickname': 'Juan',
  'phone': '+63 9XX XXX XXXX',
  'bio': 'Description here...',
  'location': '12.3456, 78.9012',  // String format for display
  'latitude': 12.3456,              // Numeric for calculations
  'longitude': 78.9012,             // Numeric for calculations
  'accountType': 'Farmer',
  'userType': 'farmer',              // lowercase version
  'profileComplete': true,           // Profile is COMPLETE on signup
  'createdAt': FieldValue.serverTimestamp(),
}
```

## Key Points

| Aspect | Detail |
|--------|--------|
| **Location Service** | Uses `geolocator: ^14.0.2` (already in pubspec) |
| **Location Format** | Lat/Long coordinates, not text address |
| **Profile Status** | `profileComplete: true` set immediately |
| **Email Verification** | Still required after signup |
| **Data Validation** | All fields validated before submission |
| **Error Handling** | Specific messages for each failure type |
| **Theme Support** | Dark mode compatible |
| **Local Storage** | All data saved to secure storage |

## Testing Checklist

- [ ] Form fills and submits successfully
- [ ] Location button triggers GPS
- [ ] Location coordinates display correctly
- [ ] Firestore document created with all fields
- [ ] Email verification still works
- [ ] Dark mode rendering correct
- [ ] Error messages display for invalid inputs
- [ ] Terms checkbox required
- [ ] Password validation enforced

## If You Need to...

### Add a new field to signup:
1. Add TextEditingController in `initState()`
2. Add field to form UI with `_buildTextField()`
3. Add field to Firebase document in `_signUpWithAllData()`
4. Add field to Firestore rules if needed

### Change location behavior:
- GPS is in `_getUserLocation()` method
- Could add Google Maps selection instead if needed
- Current format: "12.3456, 78.9012"

### Modify validation:
- Email: Uses `InputValidator.sanitizeEmail()` and `validateEmail()`
- Password: Uses `InputValidator.validatePassword()`
- Custom validation: Add to `_signUpWithAllData()` before Firestore write

### Adjust UI styling:
- Colors: `Color(0xFF00C853)` for green, theme-aware dark mode
- Font: Poppins throughout
- Spacing: 12-24px between sections
- Theme: Uses `ThemeHelper` for dark mode support

## Dependencies Used

```yaml
firebase_auth: ^4.x
cloud_firestore: ^4.x
geolocator: ^14.0.2  # GPS location
flutter_secure_storage: ^x.x  # Local storage
```

All already in pubspec.yaml - no new dependencies needed!

## Related Files

- **Firestore Rules:** `/firestore.rules` (already updated to allow user creation)
- **Theme System:** `lib/shared/theme_helper.dart`
- **Email Verification:** `lib/auth/AgriSynchVerify.dart`
- **Input Validation:** `lib/shared/input_validator.dart`
- **Error Handler:** `lib/services/error_handler.dart`

## Troubleshooting

### Location always shows "Tap Get Location"
- Check GPS is enabled on device
- Check app has location permission
- Check `geolocator` package is properly initialized

### Form won't submit
- Verify all required fields are filled
- Check browser console for errors (if web)
- Check Firestore rules allow writes

### Email verification page doesn't appear
- Verify route `/verify` exists in main.dart
- Check email verification is enabled in Firebase Auth
- Check redirect arguments passed correctly

---

**Status:** ✅ Ready for deployment  
**Created:** [Date]  
**Dependencies:** No new packages needed
