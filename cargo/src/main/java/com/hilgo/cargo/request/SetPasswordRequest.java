package com.hilgo.cargo.request;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class SetPasswordRequest {

	private String passwordCode;
	private String password;
	private String checkPassword;
}
