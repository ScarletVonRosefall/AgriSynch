# Reports System Documentation

## Overview
The AgriSynch platform now includes a comprehensive reporting system that allows users to report inappropriate products and users. Reports are reviewed and managed by administrators through the Admin Dashboard.

## Features

### 1. Report Model (`lib/models/report.dart`)
- **Fields:**
  - `id`: Unique report identifier
  - `reporterId`: User ID of the person submitting the report
  - `reporterName`: Name of the reporter
  - `reportType`: Either 'product' or 'user'
  - `reportedItemId`: ID of the reported product or user
  - `reportedItemName`: Name of the reported item
  - `category`: Category of the report (varies by type)
  - `description`: Detailed description of the issue (10-500 characters)
  - `status`: Current status (pending, reviewed, resolved, dismissed)
  - `createdAt`: Timestamp when report was created
  - `updatedAt`: Timestamp of last update

### 2. Report Service (`lib/services/report_service.dart`)
Provides comprehensive report management functionality:
- **submitReport()**: Submit a new report
- **getAllReports()**: Get all reports (admin only)
- **getReportsByStatus()**: Filter reports by status
- **getReportsByType()**: Filter reports by type (product/user)
- **updateReportStatus()**: Update report status (admin only)
- **deleteReport()**: Delete a report (admin only)
- **getPendingReportsCount()**: Get count of pending reports

### 3. Report Dialog (`lib/shared/report_dialog.dart`)
User-facing dialog for submitting reports:
- **Product Report Categories:**
  - Misleading description
  - Poor quality
  - Incorrect pricing
  - Unavailable item
  - Suspicious activity
  - Other

- **User Report Categories:**
  - Harassment
  - Spam
  - Inappropriate content
  - Fraudulent activity
  - Impersonation
  - Other

- **Validation:**
  - Category selection required
  - Description: 10-500 characters
  - Shows character count
  - Error messages for invalid input

### 4. Admin Reports Page (`lib/admin/admin_reports_page.dart`)
Admin interface for managing reports:
- **Real-time Updates**: Uses StreamBuilder for live report updates
- **Filtering:**
  - By status: All, Pending, Reviewed, Resolved, Dismissed
  - By type: Products, Users
- **Actions:**
  - View full report details in dialog
  - Update status to reviewed/resolved/dismissed
  - Delete reports
- **Report Details Dialog:**
  - Shows all report information
  - Quick action buttons for status updates
  - Visual indicators for report type and status

### 5. Integration Points

#### Browse Products Page (`lib/buyer/BrowseProductsPage.dart`)
- Report button added to each product card
- Icon: Flag (Icons.flag)
- Tooltip: "Report product"
- Opens ReportDialog with product details

#### Chat Screen (`lib/shared/chat_screen.dart`)
- Report button added to user info dialog
- Icon: Flag (Icons.flag)
- Opens ReportDialog with user details
- Allows reporting of chat partners

#### Admin Dashboard (`lib/admin/admin_dashboard.dart`)
- New "Reports" tab added to admin navigation
- Icon: Flag (Icons.flag)
- Positioned between "Support" and "Users" tabs
- Displays full AdminReportsPage

## Security Rules (`firestore.rules`)

```javascript
match /reports/{reportId} {
  // Users can create reports with validation
  allow create: if isSignedIn() 
    && request.resource.data.reporterId == request.auth.uid
    && isValidString(request.resource.data.reporterName, 100)
    && request.resource.data.reportType in ['product', 'user']
    && isValidString(request.resource.data.reportedItemId, 100)
    && isValidString(request.resource.data.reportedItemName, 200)
    && isValidString(request.resource.data.category, 100)
    && isValidString(request.resource.data.description, 500)
    && request.resource.data.status == 'pending'
    && request.resource.data.createdAt is timestamp;
  
  // Only admins can read all reports
  allow read: if isAdmin();
  
  // Only admins can update report status
  allow update: if isAdmin()
    && request.resource.data.status in ['pending', 'reviewed', 'resolved', 'dismissed'];
  
  // Only admins can delete reports
  allow delete: if isAdmin();
}
```

## User Flow

### Reporting a Product
1. User browses products in BrowseProductsPage
2. Clicks flag icon on product card
3. Selects report category from dropdown
4. Enters description (10-500 characters)
5. Submits report
6. Report is created with 'pending' status

### Reporting a User
1. User opens chat with another user
2. Clicks user info button in app bar
3. Clicks "Report" button in user info dialog
4. Selects report category from dropdown
5. Enters description (10-500 characters)
6. Submits report
7. Report is created with 'pending' status

### Admin Review Process
1. Admin logs into Admin Dashboard
2. Navigates to "Reports" tab
3. Views list of all reports with filters
4. Clicks on report to view full details
5. Takes action:
   - Mark as "Reviewed" (investigating)
   - Mark as "Resolved" (issue fixed)
   - Mark as "Dismissed" (not actionable)
   - Delete report (if spam/duplicate)
6. Report status is updated in real-time

## Database Structure

### Collection: `reports`
```javascript
{
  id: "auto-generated",
  reporterId: "user123",
  reporterName: "John Doe",
  reportType: "product", // or "user"
  reportedItemId: "product456", // or userId
  reportedItemName: "Fresh Tomatoes",
  category: "Poor quality",
  description: "Product was rotten upon delivery",
  status: "pending", // pending | reviewed | resolved | dismissed
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

## Deployment Checklist
- [x] Report model created
- [x] Report service implemented
- [x] Report dialog created
- [x] Admin reports page created
- [x] Product reporting integrated
- [x] User reporting integrated
- [x] Admin dashboard updated with Reports tab
- [x] Firestore security rules updated
- [ ] Deploy updated rules: `firebase deploy --only firestore:rules`
- [ ] Test product reporting
- [ ] Test user reporting
- [ ] Test admin report management
- [ ] Deploy web app: `flutter build web --release && firebase deploy --only hosting`

## Testing Guide

### Test Product Reporting
1. Login as a buyer
2. Browse products
3. Click flag icon on a product
4. Fill out report form and submit
5. Verify success message appears
6. Login as admin and verify report appears in Reports tab

### Test User Reporting
1. Login as a user
2. Start a chat with another user
3. Click user info button
4. Click "Report" button
5. Fill out report form and submit
6. Verify success message appears
7. Login as admin and verify report appears in Reports tab

### Test Admin Management
1. Login as admin
2. Navigate to Reports tab
3. Test filtering by status and type
4. Click on a report to view details
5. Update report status
6. Verify real-time update
7. Test delete functionality

## Future Enhancements
- Email notifications to admins for new reports
- Automated actions based on report count (e.g., auto-suspend users with 3+ reports)
- Report analytics dashboard
- User report history (for repeat offenders)
- Appeal system for dismissed reports
- Bulk actions for managing multiple reports
