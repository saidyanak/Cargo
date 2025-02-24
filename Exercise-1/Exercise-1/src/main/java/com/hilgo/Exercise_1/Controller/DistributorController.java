package com.hilgo.Exercise_1.Controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.hilgo.Exercise_1.request.DistributorRequest;
import com.hilgo.Exercise_1.responses.CargoesResponse;
import com.hilgo.Exercise_1.responses.DistributorResponse;
import com.hilgo.Exercise_1.service.DistributorService;

import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/distributor")
public class DistributorController {
	
	final private DistributorService distributorService;

	@GetMapping("/myCargoes")
	public ResponseEntity<Map<String, Object>> getMyCargoes(
			@RequestParam(defaultValue = "0") int page,
			@RequestParam(defaultValue = "10") int size,
			@RequestParam(defaultValue = "id") String sortBy
			){
		Pageable pageable = PageRequest.of(page, size, Sort.by(sortBy));
		Page<CargoesResponse> cargoPage = distributorService.getMyCargoes(pageable);
		
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
	
	@PostMapping("/update")
	public ResponseEntity<DistributorResponse> updateDist(@RequestBody DistributorRequest distributorRequest){
		return ResponseEntity.ok(distributorService.updateDist(distributorRequest));
	}
	
	@DeleteMapping("/delete")
	public ResponseEntity<Boolean> deleteDist(){
		return ResponseEntity.ok(distributorService.deleteDist());
	}
	
}
