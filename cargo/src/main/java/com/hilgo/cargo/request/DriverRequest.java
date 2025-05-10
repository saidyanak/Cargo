package com.hilgo.cargo.request;

import com.hilgo.cargo.entity.enums.CarType;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class DriverRequest {

	private String username;
	
	private CarType carType;
	
	private String phoneNumber;
	
	private String mail;
	
	private String password;
	
}
