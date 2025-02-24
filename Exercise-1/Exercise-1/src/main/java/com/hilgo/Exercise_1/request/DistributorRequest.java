package com.hilgo.Exercise_1.request;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class DistributorRequest {

	private String phoneNumber;
	private String address;
	private String username;
	private String mail;
	
}
