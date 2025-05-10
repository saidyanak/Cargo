package com.hilgo.cargo.request;

import com.hilgo.cargo.entity.enums.Roles;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class RegisterRequest {
	private String mail;
<<<<<<< HEAD
	private String username;
=======
	private String userName;
>>>>>>> 48d8eb7f47d7460a19a29f7b199df3a9bbaf84b2
	private String password;
	private String phoneNumber;
	private Roles  role;
}
