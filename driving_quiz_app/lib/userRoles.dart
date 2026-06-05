enum UserRoles { guest, admin, superAdmin }

UserRoles mapRole(String role) {
  switch (role) {
    case 'admin':
      return UserRoles.admin;
    case 'superAdmin':
      return UserRoles.superAdmin;
    default:
      return UserRoles.guest;
  }
}
