package com.hilgo.Exercise_1.responses;

import com.hilgo.Exercise_1.Entity.CarTypes;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class DriverResponse {
	
	private Long Tc;
	private CarTypes carTypes;
	private String phoneNumber;
	private String mail;
	
}
