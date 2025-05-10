package com.hilgo.cargo.request;

import com.hilgo.cargo.entity.Location;
import com.hilgo.cargo.entity.Measure;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CargoRequest {

	private String description;
	private Location selfLocation;
	private Location targetLocation;
	private Measure measure;
	private String phoneNumber;
}
