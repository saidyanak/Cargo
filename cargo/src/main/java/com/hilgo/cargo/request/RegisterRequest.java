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
	private String username;
	private String password;
	private String phoneNumber;
	private Roles  role;
}
