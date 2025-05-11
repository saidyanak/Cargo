package com.hilgo.cargo.request;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class DistributorRequest {

	private String phoneNumber;
	private AddressRequest address;
	private String username;
	private String mail;
	private String password;
}
