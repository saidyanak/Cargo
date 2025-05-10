package com.hilgo.cargo.response;

import com.hilgo.cargo.entity.Address;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class DistributorResponse {
	
	private String vkn;
	
	private String username;
	
	private Address address;
	
	private String password;
	
	private String phoneNumber;
	
	private String mail;

}
