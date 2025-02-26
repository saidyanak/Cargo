package com.hilgo.Exercise_1.request;

import com.hilgo.Exercise_1.Entity.CarTypes;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class DriverRequest {

	private String userName;
	private CarTypes carTypes;
	private String phoneNumber;
	private String mail;
}
