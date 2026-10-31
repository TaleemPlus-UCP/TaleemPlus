# TaleemPlus — Legacy Firebase Architecture Specification

> **Documentation Stage:** Pre-Migration Baseline  
> **Backend Framework:** Firebase Core 3.1.0, Firebase Auth 5.1.0, Cloud Firestore 5.0.1  
> **Client Framework:** Flutter 3.47.9 / Provider 6.1.2

---

## 1. System Topology Overview

```
+-------------------------------------------------------------------+
|                        Flutter Client App                         |
|  +-------------------+  +-------------------+  +---------------+  |
|  |  Admin Portal UI  |  | Teacher Portal UI |  | Student/Parent|  |
|  +---------+---------+  +---------+---------+  +-------+-------+  |
|            |                      |                    |          |
|            +----------------------+--------------------+          |
|                                   |                               |
|                       Provider State Management                   |
|       (AuthProvider, MemberProvider, ClassProvider, etc.)         |
+-----------------------------------+-------------------------------+
                                    |
            +-----------------------+-----------------------+
            |                                               |
            v                                               v
+-----------------------+                       +-----------------------+
|  Firebase Auth SDK    |                       |  Cloud Firestore SDK  |
| - Email/Password      |                       | - Multi-tenant queries|
| - Session Tokens      |                       | - Scoped by academy_id|
+-----------------------+                       +-----------------------+
```

---

## 2. Legacy Security Model (`firestore.rules`)

Multi-tenant security relies on Firestore Security Rules performing lookups against `users/$(request.auth.uid)`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() { return request.auth != null; }
    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }
    function isApproved() {
      let user = getUserData();
      return signedIn() && user.get('account_status', 'inactive') == "active";
    }
    function sameAcademy(docAcademyId) {
      return getUserData().get('academy_id', '') == docAcademyId;
    }

    match /classes/{classId} {
      allow read: if isApproved() && sameAcademy(resource.data.academy_id);
      allow write: if isApproved() && sameAcademy(request.resource.data.academy_id);
    }
  }
}
```

### Limitations of Legacy Model:
* High latency on initial requests due to `get()` calls in security rules.
* Heavy coupling between client app code and Firebase SDK types.
* Inability to run standalone integration tests without live Firebase emulators.
