package com.hilgo.cargo.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.hilgo.cargo.request.DriverRequest;
import com.hilgo.cargo.response.CargoResponse;
import com.hilgo.cargo.response.DriverResponse;
import com.hilgo.cargo.service.DriverService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping(path = "/driver")
@RequiredArgsConstructor
public class DriverController {

	final private DriverService driverService;

	@PostMapping("/takeCargo")
	public ResponseEntity<CargoResponse> takeCargo(@PathVariable Long cargoId){
		return ResponseEntity.ok(driverService.takeCargo(cargoId));
	}
	
	@PostMapping("/deliverCargo")
	public ResponseEntity<Boolean> deliverCargo(@PathVariable Long cargoId, @PathVariable String deliveryCode ){
		return ResponseEntity.ok(driverService.deliverCargo(cargoId, deliveryCode));
	}
	
	@PostMapping("/updateDriver")
	public ResponseEntity<DriverResponse> updateDriver(@RequestBody DriverRequest driverRequest)
	{
		return ResponseEntity.ok(driverService.updateDriver(driverRequest));
	}	
	
	
	
	
	
}
