# AgriSynch Marketplace Testing Guide
## Complete Step-by-Step Instructions for Tasks 1-10

### Prerequisites
- [ ] App is running on your device/emulator
- [ ] Firebase is connected and configured
- [ ] You have at least 2 test accounts:
  - 1 Farmer account
  - 1 Buyer account

---

## 🌾 FARMER TESTS (Tasks 1-3, 7-9)

### **Task 1-3: Product Management & Product Service**

#### Test 1A: Add a New Product
1. **Login as FARMER**
2. Navigate to **"Products"** page from bottom navigation
3. Tap the **green floating action button** (+ icon) at bottom right
4. Fill in the product form:
   - **Name**: "Fresh Tomatoes"
   - **Category**: Select "Vegetables"
   - **Price**: 50
   - **Unit**: "kg"
   - **Stock**: 100
   - **Location**: "Quezon City"
   - **Description**: "Organic farm-fresh tomatoes"
5. Tap **"Add Product"** button
6. **✓ Expected Result**: 
   - Success message appears
   - Product card appears in the list
   - Card shows vegetable icon (🌿)
   - Stock badge shows "100 available"

#### Test 1B: Add Product Photos (Task 9)
1. On the product card you just created, tap the **3-dot menu** (⋮) in top-right corner
2. Select **"Add Photos"**
3. Choose **"Camera"** or **"Gallery"**
4. Select/take a photo of tomatoes
5. Wait for upload to complete
6. Repeat to add 2-3 more photos
7. **✓ Expected Result**:
   - Photos appear on the product card
   - First photo is displayed as the main image
   - Small "X" button appears on each photo for deletion

#### Test 1C: Update Product Availability (Task 9)
1. Find the product card
2. Tap the **toggle switch** labeled "Available"
3. Turn it **OFF** (gray)
4. **✓ Expected Result**:
   - Toggle turns gray
   - Stock badge changes to "Out of Stock" in red
5. Turn it back **ON** (green)
6. **✓ Expected Result**:
   - Toggle turns green
   - Stock badge shows stock count again

#### Test 1D: Edit Product
1. Tap the **Edit icon** (pencil) on the product card
2. Change the **Price** to 55
3. Change the **Stock** to 150
4. Tap **"Update Product"**
5. **✓ Expected Result**:
   - Product card updates immediately
   - Price shows ₱55.00
   - Stock shows "150 available"

#### Test 1E: Delete a Photo
1. On the product card with photos
2. Tap the **X button** on one of the photos
3. Confirm deletion in the dialog
4. **✓ Expected Result**:
   - Photo disappears immediately
   - Remaining photos shift over

#### Test 1F: Add More Products (for variety)
Repeat Test 1A to add these products:
- **Chicken Eggs** (Category: Poultry, Price: 120, Stock: 50)
- **Fresh Milk** (Category: Dairy, Price: 80, Stock: 30)
- **Rice** (Category: Crops, Price: 45, Stock: 200)

Add photos to at least 2 of these products.

---

## 🛒 BUYER TESTS (Tasks 4-6, 10)

### **Task 4: Browse Products in Marketplace**

#### Test 4A: View Featured Products on Homepage
1. **Logout** from farmer account
2. **Login as BUYER**
3. You should land on the **Buyer Homepage**
4. **✓ Expected Result**:
   - "Featured Products" section shows product cards
   - Products have photos (if uploaded by farmer)
   - Each card shows: name, price, farmer name (👤 icon), location (📍 icon)
   - Cards are scrollable horizontally

#### Test 4B: Browse by Category
1. On Buyer Homepage, scroll to **"Browse by Category"** section
2. Tap the **"Vegetables"** category card
3. **✓ Expected Result**:
   - Navigate to Browse Products page
   - Only vegetable products appear
   - "Vegetables" filter chip is selected (green background)

#### Test 4C: Test Category Scrolling
1. On Browse Products page, look at the **category filter chips** at top
2. **Swipe left/right** on the category chips OR **use mouse wheel** to scroll
3. **✓ Expected Result**:
   - Categories scroll smoothly
   - Text is clearly readable (white text on semi-transparent background)

#### Test 4D: Filter Products
1. Tap **"All"** category chip
2. **✓ Expected Result**: All products from all farmers appear
3. Tap **"Poultry"** category chip
4. **✓ Expected Result**: Only chicken eggs (poultry) products appear
5. Tap **"Dairy"** category chip
6. **✓ Expected Result**: Only milk products appear

#### Test 4E: Search Products
1. Tap the **search bar** at top
2. Type **"tomato"**
3. **✓ Expected Result**: Only tomato products appear
4. Clear search
5. **✓ Expected Result**: All products return

#### Test 4F: View Farmer Name
1. Look at any product card
2. **✓ Expected Result**:
   - Farmer's name appears with a person icon (👤)
   - Name is clearly visible below the product name

---

### **Task 5: Shopping Cart & Checkout**

#### Test 5A: Add to Cart
1. On Browse Products page, tap a **product card** (e.g., Fresh Tomatoes)
2. In the product details dialog, set **quantity** to 5
3. Tap **"Add to Cart"**
4. **✓ Expected Result**:
   - Success message: "Added to cart"
5. Add 2-3 more different products to cart with different quantities

#### Test 5B: View Cart
1. From Buyer Homepage, tap **"Shopping Cart"** card OR
2. From Browse Products, tap the **cart icon** in app bar
3. **✓ Expected Result**:
   - All added products appear in cart
   - Each item shows: name, quantity, unit price, total price
   - Cart total is calculated correctly at bottom

#### Test 5C: Update Cart Quantity
1. In Shopping Cart, find a product
2. Use the **- button** to decrease quantity
3. Use the **+ button** to increase quantity
4. **✓ Expected Result**:
   - Quantity updates immediately
   - Item total updates
   - Cart total updates

#### Test 5D: Remove from Cart
1. Decrease quantity to **0** OR tap **remove button**
2. **✓ Expected Result**:
   - Item disappears from cart
   - Cart total recalculates

#### Test 5E: Checkout (Creates Order)
1. Ensure cart has 2-3 items
2. Note the **total amount** at bottom
3. Tap **"Checkout"** button
4. In the checkout dialog, fill in:
   - **Delivery Address**: "123 Main St, Quezon City"
   - **Notes**: "Please deliver before 5pm"
5. Tap **"Place Order"**
6. **✓ Expected Result**:
   - Success message appears
   - Navigate back to homepage
   - Cart is now empty
   - Order is created in Firestore

---

### **Task 6 & 10: View Orders as Buyer**

#### Test 6A: View Recent Orders on Homepage
1. On **Buyer Homepage**, scroll to **"Recent Orders"** section
2. **✓ Expected Result**:
   - Your order appears in the list
   - Shows order ID, total, status badge
   - Status is "pending" (orange/yellow badge)
   - **MARKETPLACE** badge appears (green, small)

#### Test 6B: View All Orders
1. From Buyer Homepage, tap **"My Orders"** in drawer menu OR
2. Tap **"View All"** in Recent Orders section
3. **✓ Expected Result**:
   - Navigate to My Orders page
   - Order appears in the list
   - **MARKETPLACE** badge is visible on the order card

#### Test 6C: Filter Orders by Status
1. On My Orders page, tap filter chips at top
2. Tap **"Pending"**
3. **✓ Expected Result**: Only pending orders appear
4. Tap **"Delivered"**
5. **✓ Expected Result**: Empty (no delivered orders yet)
6. Tap **"All"**
7. **✓ Expected Result**: All orders return

#### Test 6D: View Order Details
1. Tap on an **order card**
2. **✓ Expected Result**:
   - Bottom sheet opens
   - Shows: Order ID, date, items list, quantities, prices, total
   - Shows order status badge
   - Shows delivery address and notes

#### Test 6E: Cancel Pending Order
1. In order details bottom sheet (while status is "pending")
2. Tap **"Cancel Order"** button (red)
3. Confirm cancellation in dialog
4. **✓ Expected Result**:
   - Success message appears
   - Status badge changes to "CANCELLED" (gray/red)
   - Order updates in real-time

---

## 🌾 FARMER ORDER MANAGEMENT (Tasks 7-8)

### **Task 7: View Orders as Farmer**

#### Test 7A: View Orders
1. **Logout** from buyer account
2. **Login as FARMER** (the one who created the products)
3. Navigate to **"Orders"** page from bottom navigation
4. **✓ Expected Result**:
   - The order placed by buyer appears
   - **MARKETPLACE** badge is visible (green)
   - Status shows "pending"
   - Shows buyer name, total, order date

#### Test 7B: View Order Details
1. Tap on the **order card**
2. **✓ Expected Result**:
   - Bottom sheet opens
   - Shows all order details: items, quantities, prices
   - Shows buyer information
   - Shows delivery address and notes from buyer

---

### **Task 8: Update Order Status & Auto-Finance**

#### Test 8A: Change Status to Confirmed
1. On the order card, tap **"Update Status"** button
2. Select **"confirmed"** from the list
3. Tap **"Update"**
4. **✓ Expected Result**:
   - Status badge updates to "CONFIRMED" (blue)
   - No finance transaction (only happens on "delivered")

#### Test 8B: Change Status to Preparing
1. Tap **"Update Status"** again
2. Select **"preparing"**
3. Tap **"Update"**
4. **✓ Expected Result**:
   - Status badge updates to "PREPARING" (orange)

#### Test 8C: Change Status to Delivering
1. Tap **"Update Status"** again
2. Select **"delivering"**
3. Tap **"Update"**
4. **✓ Expected Result**:
   - Status badge updates to "DELIVERING" (purple)

#### Test 8D: Change Status to Delivered (Auto-Finance)
1. **Before updating**, navigate to **"Finances"** page
2. Note your current **Total Balance** amount
3. Go back to **"Orders"** page
4. Tap **"Update Status"** on the order
5. Select **"delivered"**
6. Tap **"Update"**
7. **✓ Expected Result**:
   - A **preview dialog** appears showing:
     - Wallet icon 💰
     - "Order Delivered - Payment Received"
     - Transaction amount (order total)
     - Finance transaction preview
   8. Tap **"OK"** to close dialog
   9. Navigate back to **"Finances"** page
   10. **✓ Expected Result**:
       - New transaction appears at top
       - Type: "Product Sale"
       - Amount: Order total (green, positive)
       - Total Balance increased by order amount
       - Status badge on order is "DELIVERED" (green)

---

## 🔄 REAL-TIME UPDATES TEST

### **Task 6 & 7: Test Real-Time Synchronization**

#### Test RT1: See Order Updates in Real-Time (2 Devices Required)
1. **Device 1**: Login as FARMER
2. **Device 2**: Login as BUYER
3. **Buyer**: Navigate to "My Orders" page
4. **Farmer**: Update order status to "confirmed"
5. **✓ Expected Result on Buyer device**:
   - Order status updates automatically (no refresh needed)
   - Status badge changes color
6. **Farmer**: Update to "preparing"
7. **✓ Expected Result on Buyer device**:
   - Updates in real-time again

#### Test RT2: See New Orders Appear (2 Devices Required)
1. **Device 1**: Farmer on "Orders" page
2. **Device 2**: Buyer places a new order
3. **✓ Expected Result on Farmer device**:
   - New order appears automatically in the list
   - No refresh needed

---

## 📦 STOCK MANAGEMENT TEST

### **Task 2 & 5: Verify Stock Decreases After Checkout**

#### Test SM1: Check Stock Before Order
1. **Login as FARMER**
2. Go to **"Products"** page
3. Find "Fresh Tomatoes" product
4. Note the **stock amount** (e.g., 150)

#### Test SM2: Place Order as Buyer
1. **Logout and login as BUYER**
2. Add **10 kg** of "Fresh Tomatoes" to cart
3. Checkout and place order

#### Test SM3: Verify Stock Decreased
1. **Logout and login as FARMER**
2. Go to **"Products"** page
3. Find "Fresh Tomatoes" product
4. **✓ Expected Result**:
   - Stock decreased by 10 (now shows 140)
   - Updated automatically after checkout

---

## 🖼️ IMAGE UPLOAD COMPLETE TEST

### **Task 9: Full Image Upload Flow**

#### Test IMG1: Upload from Camera
1. **Login as FARMER**
2. Add a new product OR edit existing one
3. Tap 3-dot menu → **"Add Photos"**
4. Select **"Camera"**
5. Take a photo
6. **✓ Expected Result**:
   - Photo uploads to Firebase Storage
   - Photo appears on product card
   - Photo is visible on buyer's browse page

#### Test IMG2: Upload from Gallery
1. On same or different product
2. Tap 3-dot menu → **"Add Photos"**
3. Select **"Gallery"**
4. Choose a photo from device
5. **✓ Expected Result**:
   - Photo uploads successfully
   - Appears on product card

#### Test IMG3: Multiple Photos
1. Add 3-4 photos to a single product
2. **✓ Expected Result**:
   - All photos display on product card
   - First photo is the main display image

#### Test IMG4: Delete Photo
1. Tap **X button** on a photo
2. Confirm deletion
3. **✓ Expected Result**:
   - Photo removed from product card
   - Photo deleted from Firebase Storage
   - Other photos remain

#### Test IMG5: Photos Display on Buyer Side
1. **Login as BUYER**
2. Go to Browse Products
3. Find products with photos
4. **✓ Expected Result**:
   - Product photos display correctly
   - Photos show in:
     - Featured Products (homepage)
     - Browse Products page
     - Product detail view

---

## 🎯 COMPLETE END-TO-END TEST

### **Full Marketplace Flow (All Tasks Combined)**

1. **FARMER**: Create product "Mangoes" with photo ✓
2. **FARMER**: Set price ₱150/kg, stock 50 ✓
3. **BUYER**: Browse and find Mangoes ✓
4. **BUYER**: Add 5kg to cart ✓
5. **BUYER**: Checkout with delivery address ✓
6. **VERIFY**: Stock decreased to 45 ✓
7. **BUYER**: See order in "My Orders" with MARKETPLACE badge ✓
8. **FARMER**: See new order appear in "Orders" page ✓
9. **FARMER**: Update status: pending → confirmed → preparing → delivering ✓
10. **BUYER**: See status updates in real-time ✓
11. **FARMER**: Update status to "delivered" ✓
12. **VERIFY**: Finance transaction auto-created ✓
13. **VERIFY**: Farmer balance increased by ₱750 ✓
14. **BUYER**: See final status as "DELIVERED" ✓

---

## ✅ CHECKLIST SUMMARY

### Task 1-3: Product Management
- [ ] Add product
- [ ] Edit product
- [ ] Delete product photos
- [ ] Toggle availability
- [ ] View product list

### Task 4: Browse Products
- [ ] View featured products
- [ ] Filter by category
- [ ] Search products
- [ ] See farmer name
- [ ] Scroll categories

### Task 5: Shopping Cart
- [ ] Add to cart
- [ ] Update quantity
- [ ] Remove from cart
- [ ] Checkout
- [ ] Stock decreases

### Task 6: Order Service
- [ ] Orders appear for buyer
- [ ] Orders appear for farmer
- [ ] Real-time updates work

### Task 7: Farmer Orders Page
- [ ] View Firestore orders
- [ ] MARKETPLACE badge visible
- [ ] Order details shown

### Task 8: Auto-Finance
- [ ] Status update to delivered
- [ ] Finance preview dialog
- [ ] Transaction created
- [ ] Balance updated

### Task 9: Image Upload
- [ ] Upload from camera
- [ ] Upload from gallery
- [ ] Multiple photos
- [ ] Delete photos
- [ ] Photos display everywhere

### Task 10: Buyer Orders Page
- [ ] Real-time order updates
- [ ] MARKETPLACE badge
- [ ] Filter by status
- [ ] Cancel pending orders
- [ ] View order details

---

## 🐛 Common Issues & Solutions

### Issue: "No products appear"
**Solution**: Make sure you're logged in as farmer and have added products first

### Issue: "Stock doesn't decrease"
**Solution**: Check Firebase rules allow writes to products collection

### Issue: "Orders don't appear"
**Solution**: 
- Check Firestore rules allow reads/writes to orders collection
- Verify you're logged in with correct user type

### Issue: "Photos don't upload"
**Solution**: 
- Check Firebase Storage rules
- Ensure internet connection is stable
- Verify storage bucket is configured

### Issue: "Real-time updates don't work"
**Solution**: 
- Check internet connection
- Verify Firestore StreamBuilder is working
- Try refreshing the page

### Issue: "Finance transaction not created"
**Solution**: 
- Ensure order status is exactly "delivered"
- Check FinanceService is properly initialized
- Verify Firestore rules allow writes to finances collection

---

## 📱 Testing Devices

**Recommended Setup**:
- Test on both Android and iOS if possible
- Use 2 devices/emulators simultaneously for real-time tests
- Test with slow internet to verify loading states

**Minimum Setup**:
- 1 device with ability to login as both farmer and buyer

---

## ✨ Success Criteria

All tasks pass if:
- ✅ Products can be created, edited, deleted
- ✅ Photos upload and display correctly
- ✅ Buyers can browse and filter products
- ✅ Shopping cart works completely
- ✅ Orders appear for both buyer and farmer
- ✅ Order status updates work
- ✅ Auto-finance triggers on delivery
- ✅ Stock decreases after purchase
- ✅ Real-time updates work
- ✅ All MARKETPLACE badges display

**You're ready to ship when all checkboxes are ✓!** 🚀
