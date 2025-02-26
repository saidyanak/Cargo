package com.hilgo.Exercise_1.responses;

import com.hilgo.Exercise_1.Entity.Sizes;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class CargoResponse {

	private String description;
	private String selfLocation;
	private String targetLocation;
	private Double weight;
	private Sizes sizes;
	private String distributorPhoneNumber;
	
}
