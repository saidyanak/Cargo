package com.hilgo.cargo.request;

import com.hilgo.cargo.entity.Address;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DistributorRequest {

	private String phoneNumber;
	private Address address;
	private String username;
	private String mail;
	private String password;
}
