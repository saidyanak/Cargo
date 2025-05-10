package com.hilgo.cargo.response;

import com.hilgo.cargo.entity.enums.CargoSituation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class CargoesResponse {

	private Long id;
	
	private ResponseLocation selfLocation;
	
	private ResponseLocation targetLocation;
	
	private ResponseMeasure responseMeasure;
	
	private CargoSituation cargoSituation;
	
	private String phoneNumber;

	private String distPhoneNumber;
}
