package com.hilgo.cargo.controller;

<<<<<<< HEAD
import org.springframework.http.ResponseEntity;
=======
import java.util.HashMap;
import java.util.Map;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
>>>>>>> 48d8eb7f47d7460a19a29f7b199df3a9bbaf84b2
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
<<<<<<< HEAD
import org.springframework.web.bind.annotation.RestController;

import com.hilgo.cargo.request.DriverRequest;
import com.hilgo.cargo.response.CargoResponse;
=======
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.hilgo.cargo.request.DriverRequest;
import com.hilgo.cargo.response.CargoesResponse;
>>>>>>> 48d8eb7f47d7460a19a29f7b199df3a9bbaf84b2
import com.hilgo.cargo.response.DriverResponse;
import com.hilgo.cargo.service.DriverService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping(path = "/driver")
@RequiredArgsConstructor
public class DriverController {

	final private DriverService driverService;

	@PostMapping("/takeCargo")
<<<<<<< HEAD
	public ResponseEntity<CargoResponse> takeCargo(@PathVariable Long cargoId){
=======
	public ResponseEntity<Boolean> takeCargo(@PathVariable Long cargoId){
>>>>>>> 48d8eb7f47d7460a19a29f7b199df3a9bbaf84b2
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
<<<<<<< HEAD
	}	
	
=======
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

>>>>>>> 48d8eb7f47d7460a19a29f7b199df3a9bbaf84b2
	
	
	
	
}
