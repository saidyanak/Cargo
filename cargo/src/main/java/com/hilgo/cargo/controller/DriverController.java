package com.hilgo.cargo.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.hilgo.cargo.request.DriverRequest;
import com.hilgo.cargo.response.CargoesResponse;
import com.hilgo.cargo.response.DriverResponse;
import com.hilgo.cargo.service.DriverService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping(path = "/driver")
@RequiredArgsConstructor
public class DriverController {

	final private DriverService driverService;

	@PostMapping("/takeCargo")
	public ResponseEntity<Boolean> takeCargo(@PathVariable Long cargoId){
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
	
	@GetMapping("/myCargoes")
	public ResponseEntity<Map<String, Object>> getMyCargoes(
			@RequestParam(defaultValue = "0") int page,
			@RequestParam(defaultValue = "10") int size,
			@RequestParam(defaultValue = "id") String sortBy
			){
		Pageable pageable = PageRequest.of(page, size, Sort.by(sortBy));
		Page<CargoesResponse> cargoPage = driverService.getMyCargoes(pageable);
		Map<String, Object> meta = new HashMap<String, Object>();
		meta.put("currentPage", cargoPage.getNumber());
		meta.put("totalItems", cargoPage.getTotalElements());
		meta.put("pageSize", cargoPage.getSize());
		meta.put("isFirst", cargoPage.isFirst());
		meta.put("isLast", cargoPage.isLast());
		
		Map<String, Object> response = new HashMap<String, Object>();
		response.put("data", cargoPage.getContent());
		response.put("meta", meta);
		return ResponseEntity.ok(response);
	}

	@GetMapping
	public ResponseEntity<Map<String, Object>> getAllCargoes(
			@RequestParam(defaultValue = "0") int page,
			@RequestParam(defaultValue = "10") int size,
			@RequestParam(defaultValue = "id") String sortBy
			){
		Pageable pageable = PageRequest.of(page, size, null);
		Page<CargoesResponse> cargoPage = driverService.getAllCargoes(pageable);
		
		Map<String, Object> meta = new HashMap<String, Object>();
		meta.put("currentPage", cargoPage.getNumber());
		meta.put("totalItems", cargoPage.getTotalElements());
		meta.put("pageSize", cargoPage.getSize());
		meta.put("isFirst", cargoPage.isFirst());
		meta.put("isLast", cargoPage.isLast());
		
		Map<String, Object> response = new HashMap<String, Object>();
		response.put("data", cargoPage.getContent());
		response.put("meta", meta);
		return ResponseEntity.ok(response);
		
	}

	
	
	
	
}
