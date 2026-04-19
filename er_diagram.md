# Entity Relationship Diagram

The following ER diagram maps the primary relationships and schema structure of the `Student Attendance & Registration System`.

```mermaid
erDiagram
    STUDENTS {
        NUMBER StudentID PK
        VARCHAR2 RollNumber UK
        VARCHAR2 Name
        VARCHAR2 Email UK
        VARCHAR2 Branch
        NUMBER BatchYear
        NUMBER CurrentYear
        VARCHAR2 ProgramLevel
        VARCHAR2 Status
    }

    FACULTY {
        NUMBER FacultyID PK
        VARCHAR2 Name
        VARCHAR2 Email UK
        VARCHAR2 Department
        VARCHAR2 Designation
    }

    ADMINS {
        VARCHAR2 Name
        VARCHAR2 Email PK
        VARCHAR2 Password
    }

    SESSIONS {
        NUMBER SessionID PK
        VARCHAR2 SessionName
        VARCHAR2 AcademicYear
        DATE StartDate
        DATE EndDate
        CHAR IsActive
    }

    COURSES {
        NUMBER CourseID PK
        VARCHAR2 CourseCode UK
        VARCHAR2 CourseName
        NUMBER Credits
        VARCHAR2 Department
        VARCHAR2 CourseLevel
        VARCHAR2 SemesterType
        VARCHAR2 CourseCategory
        NUMBER RecommendedYear
    }
    
    COURSE_PREREQUISITES {
        NUMBER CourseID FK
        NUMBER PrereqCourseID FK
    }

    COURSE_INSTANCES {
        NUMBER InstanceID PK
        NUMBER CourseID FK
        NUMBER SessionID FK
        NUMBER MaxCapacity
    }

    SECTIONS {
        NUMBER SectionID PK
        NUMBER InstanceID FK
        VARCHAR2 SectionName UK
        NUMBER FacultyID FK
        VARCHAR2 Room
        VARCHAR2 Slot1
        VARCHAR2 Slot2
        NUMBER EnrolledCount
        NUMBER MaxStudents
    }

    BATCHES {
        NUMBER BatchID PK
        VARCHAR2 BatchName
        NUMBER CourseID FK
        NUMBER SessionID FK
        NUMBER CoordinatorID FK
    }

    STUDENT_REGISTRATIONS {
        NUMBER RegistrationID PK
        NUMBER StudentID FK
        NUMBER SectionID FK
        DATE RegistrationDate
        VARCHAR2 RegStatus
        VARCHAR2 Grade
    }

    ATTENDANCE {
        NUMBER AttendanceID PK
        NUMBER StudentID FK
        NUMBER SectionID FK
        DATE AttendanceDate
        NUMBER SlotNumber
        VARCHAR2 AttStatus
        NUMBER MarkedBy FK
        TIMESTAMP MarkedAt
    }

    ADMISSION_DROP_LOG {
        NUMBER LogID PK
        NUMBER StudentID FK
        VARCHAR2 Action
        DATE ActionDate
        VARCHAR2 Reason
        VARCHAR2 PerformedBy
    }

    %% Relationships
    COURSES ||--o{ COURSE_INSTANCES : "creates"
    COURSES ||--o{ COURSE_PREREQUISITES : "has"
    COURSES ||--o{ COURSE_PREREQUISITES : "serves as"
    SESSIONS ||--o{ COURSE_INSTANCES : "includes"
    
    COURSE_INSTANCES ||--o{ SECTIONS : "has"
    FACULTY ||--o{ SECTIONS : "coordinates"

    COURSES ||--o{ BATCHES : "contains"
    SESSIONS ||--o{ BATCHES : "groups by"
    FACULTY ||--o{ BATCHES : "monitors"

    STUDENTS ||--o{ STUDENT_REGISTRATIONS : "enrolls in"
    SECTIONS ||--o{ STUDENT_REGISTRATIONS : "has enrolled"

    STUDENTS ||--o{ ATTENDANCE : "marked for"
    SECTIONS ||--o{ ATTENDANCE : "logged in"
    FACULTY ||--o{ ATTENDANCE : "marked by"

    STUDENTS ||--o{ ADMISSION_DROP_LOG : "tracked by"
```

## Description of Key Relationships

1. **Course Structure**: A `COURSE` combined with a `SESSION` forms a `COURSE_INSTANCE` (e.g. "Intro to Programming" in "Even Semester 24-25"). 
2. **Sections**: A `COURSE_INSTANCE` is broken down into `SECTIONS`. A `FACULTY` member handles each section, and students enroll directly into specific `SECTIONS` via `STUDENT_REGISTRATIONS`.
3. **Attendance Tracking**: `ATTENDANCE` acts as a log entry linking a `STUDENT` and a `SECTION` for a specific day and time slot. `FACULTY` members are associated as the marker of this attendance.
4. **Lifecycle Logs**: The `ADMISSION_DROP_LOG` tracks major lifecycle changes for a student independent of specific courses.
