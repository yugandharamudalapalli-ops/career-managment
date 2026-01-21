import Map "mo:core/Map";
import Array "mo:core/Array";
import Text "mo:core/Text";
import Iter "mo:core/Iter";
import Order "mo:core/Order";
import Runtime "mo:core/Runtime";
import Principal "mo:core/Principal";
import MixinAuthorization "authorization/MixinAuthorization";
import AccessControl "authorization/access-control";

actor {
  // Types
  public type AcademicDetails = {
    degree : Text;
    gpa : Float;
    graduationYear : Nat;
  };

  public type CareerInfo = {
    careerPath : Text;
    skills : [Text];
    experienceLevel : Text;
  };

  public type ContactInfo = {
    email : Text;
    phone : Text;
    address : Text;
  };

  public type StudentProfile = {
    id : Nat;
    name : Text;
    academicDetails : AcademicDetails;
    careerInfo : CareerInfo;
    contactInfo : ContactInfo;
  };

  public type CareerPath = {
    name : Text;
    description : Text;
  };

  public type UserProfile = {
    name : Text;
    email : Text;
  };

  module StudentProfile {
    public func compareByName(a : StudentProfile, b : StudentProfile) : Order.Order {
      Text.compare(a.name, b.name);
    };
  };

  // State
  let accessControlState = AccessControl.initState();
  include MixinAuthorization(accessControlState);

  let studentProfiles = Map.empty<Nat, StudentProfile>();
  let careerPaths = Map.empty<Text, CareerPath>();
  let userProfiles = Map.empty<Principal, UserProfile>();
  var nextStudentId = 1;

  // User Profile Management (Required by instructions)
  public query ({ caller }) func getCallerUserProfile() : async ?UserProfile {
    if (not (AccessControl.hasPermission(accessControlState, caller, #user))) {
      Runtime.trap("Unauthorized: Only users can access profiles");
    };
    userProfiles.get(caller);
  };

  public query ({ caller }) func getUserProfile(user : Principal) : async ?UserProfile {
    if (caller != user and not AccessControl.isAdmin(accessControlState, caller)) {
      Runtime.trap("Unauthorized: Can only view your own profile");
    };
    userProfiles.get(user);
  };

  public shared ({ caller }) func saveCallerUserProfile(profile : UserProfile) : async () {
    if (not (AccessControl.hasPermission(accessControlState, caller, #user))) {
      Runtime.trap("Unauthorized: Only users can save profiles");
    };
    userProfiles.add(caller, profile);
  };

  // Student Profile Management (Admin-only)
  public shared ({ caller }) func addStudentProfile(profile : StudentProfile) : async Nat {
    if (not (AccessControl.hasPermission(accessControlState, caller, #admin))) {
      Runtime.trap("Unauthorized: Only admins can add student profiles");
    };

    let id = nextStudentId;
    let newProfile : StudentProfile = {
      profile with id;
    };
    studentProfiles.add(id, newProfile);
    nextStudentId += 1;
    id;
  };

  public shared ({ caller }) func updateStudentProfile(id : Nat, profile : StudentProfile) : async () {
    if (not (AccessControl.hasPermission(accessControlState, caller, #admin))) {
      Runtime.trap("Unauthorized: Only admins can update student profiles");
    };

    if (not studentProfiles.containsKey(id)) {
      Runtime.trap("Student profile not found");
    };

    let updatedProfile : StudentProfile = {
      profile with id;
    };
    studentProfiles.add(id, updatedProfile);
  };

  public shared ({ caller }) func deleteStudentProfile(id : Nat) : async () {
    if (not (AccessControl.hasPermission(accessControlState, caller, #admin))) {
      Runtime.trap("Unauthorized: Only admins can delete student profiles");
    };

    if (not studentProfiles.containsKey(id)) {
      Runtime.trap("Student profile not found");
    };

    studentProfiles.remove(id);
  };

  // Public read access - no authentication required for public career information view
  public query ({ caller }) func getStudentProfile(id : Nat) : async StudentProfile {
    switch (studentProfiles.get(id)) {
      case (null) { Runtime.trap("Student profile not found") };
      case (?profile) { profile };
    };
  };

  public query ({ caller }) func getAllStudentProfiles() : async [StudentProfile] {
    studentProfiles.values().toArray();
  };

  // Career Path Management
  public shared ({ caller }) func addCareerPath(path : CareerPath) : async () {
    if (not (AccessControl.hasPermission(accessControlState, caller, #admin))) {
      Runtime.trap("Unauthorized: Only admins can add career paths");
    };

    careerPaths.add(path.name, path);
  };

  // Public read access - no authentication required
  public query ({ caller }) func getCareerPath(name : Text) : async CareerPath {
    switch (careerPaths.get(name)) {
      case (null) { Runtime.trap("Career path not found") };
      case (?path) { path };
    };
  };

  public query ({ caller }) func getAllCareerPaths() : async [CareerPath] {
    careerPaths.values().toArray();
  };

  // Search and Filter - Public access for browsing career information
  public query ({ caller }) func searchStudentsByName(name : Text) : async [StudentProfile] {
    studentProfiles.values().toArray().filter(
      func(profile) {
        profile.name.toLower().contains(#text(name.toLower()));
      }
    );
  };

  public query ({ caller }) func filterStudentsByCareerPath(careerPath : Text) : async [StudentProfile] {
    studentProfiles.values().toArray().filter(
      func(profile) {
        profile.careerInfo.careerPath == careerPath;
      }
    );
  };

  public query ({ caller }) func filterStudentsByDegree(degree : Text) : async [StudentProfile] {
    studentProfiles.values().toArray().filter(
      func(profile) {
        profile.academicDetails.degree == degree;
      }
    );
  };

  public query ({ caller }) func filterStudentsByGraduationYear(year : Nat) : async [StudentProfile] {
    studentProfiles.values().toArray().filter(
      func(profile) {
        profile.academicDetails.graduationYear == year;
      }
    );
  };

  public query ({ caller }) func combinedFilter(
    name : ?Text,
    careerPath : ?Text,
    degree : ?Text,
    graduationYear : ?Nat,
  ) : async [StudentProfile] {
    studentProfiles.values().toArray().filter(
      func(profile) {
        let nameMatch = switch (name) {
          case (null) { true };
          case (?n) { profile.name.toLower().contains(#text(n.toLower())) };
        };

        let careerPathMatch = switch (careerPath) {
          case (null) { true };
          case (?cp) { profile.careerInfo.careerPath == cp };
        };

        let degreeMatch = switch (degree) {
          case (null) { true };
          case (?d) { profile.academicDetails.degree == d };
        };

        let yearMatch = switch (graduationYear) {
          case (null) { true };
          case (?y) { profile.academicDetails.graduationYear == y };
        };

        nameMatch and careerPathMatch and degreeMatch and yearMatch;
      }
    );
  };
};
