package com.hilgo.cargo.response;

import com.hilgo.cargo.request.AddressRequest;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class DistributorResponse {
	
	private String token;

	private String vkn;
	
	private String username;
	
	private AddressRequest address;
	
	private String password;
	
	private String phoneNumber;
	
	private String mail;

}
