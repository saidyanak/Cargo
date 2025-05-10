package com.hilgo.cargo.response;

import com.hilgo.cargo.entity.enums.CarType;

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
public class DriverResponse {

	private String tc;
	
	private String username;
	
	private CarType carType;
	
	private String password;
	
	private String phoneNumber;
	
	private String mail;
}
