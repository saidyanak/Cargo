package com.hilgo.Exercise_1.responses;



import com.hilgo.Exercise_1.Entity.CargoSituation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Builder
@Data
@AllArgsConstructor
@NoArgsConstructor
public class CargoesResponse {
	long cargoId;
	String description;
	CargoSituation cargoSituation;
	String phoneNumber;
	
	
}
