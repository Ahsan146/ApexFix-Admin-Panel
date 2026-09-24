# ApexFix Admin Panel

Separate Flutter Web administration panel for the ApexFix home-services platform.

## Included

- ApexFix branding: Roboto typography and yellow **Fix** accent.
- Firebase Authentication gate.
- Firebase custom-claim admin authorization.
- Live Firestore dashboard metrics.
- Customers, technicians, bookings and service catalog views.
- Responsive desktop-first SaaS dashboard layout.
- Admin-safe Firestore rules using `request.auth.token.admin == true`.

## Firebase setup

The panel targets the existing **apexfix** Firebase project and uses the same Web Firebase configuration as the customer application.

Before using the admin dashboard against production data:

1. Enable Email/Password authentication in Firebase Authentication.
2. Create the admin user in Firebase Authentication.
3. Give that user the Firebase custom claim `admin: true` using a trusted server/Admin SDK. Never put a service-account key in this repository.
4. Deploy the included `firestore.rules` to the existing ApexFix Firebase project.
5. Run:
   ```
   flutter pub get
   flutter run -d chrome
   ```

## Important security note

Firebase Web API keys are identifiers, not service-account secrets. The admin authorization boundary is enforced by Firebase Authentication custom claims and Firestore Security Rules. Do not ship a Firebase service-account JSON file or Admin SDK private key to the browser.

## Project

ApexFix-Admin-Panel
