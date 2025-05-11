package com.hilgo.cargo.controller;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.hilgo.cargo.request.CargoRequest;
import com.hilgo.cargo.request.DistributorRequest;
import com.hilgo.cargo.response.CargoResponse;
import com.hilgo.cargo.response.CargoesResponse;
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
	
	@DeleteMapping("/deleteCargo/{cargoId}")
	public ResponseEntity<Boolean> deleteCargo(@PathVariable("cargoId") Long cargoId) {
		return ResponseEntity.ok(distributorService.deleteCargo(cargoId));
	}
	
	@PutMapping("/updateCargo/{cargoId}")
	public ResponseEntity<CargoResponse> updateCargo(@PathVariable("cargoId") Long cargoId, @RequestBody CargoRequest cargoRequest){
		return ResponseEntity.ok(distributorService.updateCargo(cargoId, cargoRequest));
	}

	
	@GetMapping("/getMyCargoes")
	public ResponseEntity<Map<String, Object>> getMyCargoes(
		@RequestParam(defaultValue = "0") int page,
		@RequestParam(defaultValue = "10") int size,
		@RequestParam(defaultValue = "id") String sortBy
	) {
	
		Pageable pageable = PageRequest.of(page, size, Sort.by(sortBy));
		Page<CargoesResponse> cargopage = distributorService.getMyCargoes(pageable);
		Map<String, Object> meta = new HashMap<String , Object>();
		meta.put("currentPage", cargopage.getNumber());
		meta.put("totalItems", cargopage.getTotalElements());
		meta.put("pageSize", cargopage.getSize());
		meta.put("isFirst", cargopage.isFirst());
		meta.put("isLast", cargopage.isLast());
		
		Map<String, Object> response = new HashMap<String , Object>();
		response.put("data", cargopage.getContent());
		response.put("meta", meta);
		return ResponseEntity.ok(response);
	}
	
	

}
