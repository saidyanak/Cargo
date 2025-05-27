package com.hilgo.cargo.response;

import java.time.LocalDateTime;

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

	private String description;
	
	private ResponseLocation selfLocation;
	
	private ResponseLocation targetLocation;
	
	private ResponseMeasure responseMeasure;
	
	private CargoSituation cargoSituation;
	
	private String phoneNumber;

	private String distPhoneNumber;

	private LocalDateTime createdAt; 
    
	private LocalDateTime updatedAt; 
    
	private String verificationCode;
}
