package com.hilgo.cargo.response;


import com.hilgo.cargo.entity.Location;
import com.hilgo.cargo.entity.Measure;
import com.hilgo.cargo.entity.enums.CargoSituation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CargoResponse {

	private String description;
	private Location selfLocation;
	private Location targetLocation;
	private Measure measure;
	private String phoneNumber;
	private CargoSituation cargoSituation;
}
