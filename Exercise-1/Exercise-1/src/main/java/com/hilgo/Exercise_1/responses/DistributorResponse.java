package com.hilgo.Exercise_1.responses;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DistributorResponse {
	
	private String username;
	private String mail;
	private String phoneNumber;
	private String address;
	private long vkn;

}
