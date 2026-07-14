# TaleemPlus — Project Skeleton

This is the starter folder structure for the 60-day solo build plan
(`TaleemPlus_60Day_Plan.md`). Every file is a stub with a one-line comment
saying what belongs there and which SDS section / week it maps to — nothing
here runs yet. Fill it in feature-by-feature, in the order the plan lays out.

## Structure

```
taleemplus_app/
├── lib/
│   ├── main.dart              # App entry point, Firebase/DB init, routing
│   ├── core/
│   │   ├── theme/             # App-wide colors/text styles
│   │   ├── constants/         # Route names, table names, pref keys
│   │   └── utils/             # Validators, date helpers
│   ├── data/
│   │   ├── local/
│   │   │   ├── db_helper.dart # SQLite setup — Week 1
│   │   │   └── tables/        # One file per table, matches Fig.7 ERD
│   │   ├── remote/            # Firebase service + sync_service.dart (Week 7)
│   │   ├── models/            # Dart classes matching Fig.4 Class Diagram
│   │   └── repositories/      # Bridge between UI and local/remote data
│   ├── logic/                 # Providers (state management)
│   ├── features/
│   │   ├── auth/              # Login/signup — Week 1
│   │   ├── admin/             # Week 2
│   │   ├── teacher/           # Weeks 3-4 (attendance, OCR, test gen)
│   │   ├── student/           # Week 5 (summarizer, quiz)
│   │   └── parent/            # Week 7
│   ├── services/ai/           # OCR, summarizer, test generator, risk predictor
│   └── widgets/                # Shared components incl. role_guard.dart (RBAC)
├── assets/
│   ├── images/
│   └── ml_models/             # risk_model.tflite goes here (Week 6)
├── test/
│   ├── unit/                  # Maps to Table 4 test cases
│   └── integration/           # Offline/sync end-to-end tests
├── ml_training/                # Python side — NOT part of the Flutter app
│   ├── train_risk_model.py    # Week 6, Day 36-37
│   ├── export_tflite.py       # Week 6, Day 38
│   ├── requirements.txt
│   └── data/synthetic_dataset.csv
└── pubspec.yaml                # All dependencies already listed
```

## Before you write any feature code

1. `flutter pub get`
2. `flutterfire configure` (sets up Firebase for this project)
3. Fill in `lib/data/local/db_helper.dart` first — every table file and
   repository depends on it.
4. Build `lib/features/auth/login_screen.dart` + RBAC (`role_guard.dart`)
   next — you can't test any role-specific screen without it.

## Reference

Every stub comment points back to either a Figure/Section in your SDS or a
Week/Day in `TaleemPlus_60Day_Plan.md`. If you're ever unsure what a file
should contain, check that plan first.
