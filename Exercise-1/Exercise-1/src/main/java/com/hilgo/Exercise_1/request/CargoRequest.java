package com.hilgo.Exercise_1.request;

import com.hilgo.Exercise_1.Entity.CargoSituation;
import com.hilgo.Exercise_1.Entity.Sizes;

import jakarta.persistence.Column;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class CargoRequest {

	private String selfLocation;
	private String targetLocation;
	private Double weight;
	private Sizes sizes;
	private String phoneNumber;
	private String description;
	
}
