package com.hilgo.cargo.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.hilgo.cargo.request.CargoRequest;
import com.hilgo.cargo.request.DistributorRequest;
import com.hilgo.cargo.response.CargoResponse;
import com.hilgo.cargo.response.DistributorResponse;
import com.hilgo.cargo.service.DistributorService;

import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/distributor")
public class DistributorController {
	
	final private DistributorService distributorService;
	
	@PostMapping("/updateDistributor")
	public ResponseEntity<DistributorResponse> updateDistributor(@RequestBody DistributorRequest distributorRequest){
		return ResponseEntity.ok(distributorService.updateDistributor(distributorRequest));
	}
	
	@PostMapping("/addCargo")
	public ResponseEntity<List<CargoResponse>> addCargo(@RequestBody CargoRequest cargoRequest){
		return ResponseEntity.ok(distributorService.addCargo(cargoRequest));
	}
	
	@DeleteMapping("/deleteCargo")
	public ResponseEntity<Boolean> deleteCargo(@PathVariable Long cargoId) {
		return ResponseEntity.ok(distributorService.deleteCargo(cargoId));
	}
	
	@PostMapping("/updateCargo")
	public ResponseEntity<CargoResponse> updateCargo(@PathVariable Long cargoId, @RequestBody CargoRequest cargoRequest){
		return ResponseEntity.ok(distributorService.updateCargo(cargoId, cargoRequest));
	}

}
