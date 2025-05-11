package com.hilgo.cargo.request;

import com.hilgo.cargo.response.ResponseLocation;
import com.hilgo.cargo.response.ResponseMeasure;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CargoRequest {

	private String description;
	private ResponseLocation selfLocation;
	private ResponseLocation targetLocation;
	private ResponseMeasure measure;
	private String phoneNumber;
}
