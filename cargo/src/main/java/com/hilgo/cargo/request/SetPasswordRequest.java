package com.hilgo.cargo.request;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SetPasswordRequest {

	private String passwordCode;
	private String password;
	private String checkPassword;
}
