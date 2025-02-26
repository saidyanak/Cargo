package com.hilgo.Exercise_1.service;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.Random;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import com.hilgo.Exercise_1.Entity.Cargo;
import com.hilgo.Exercise_1.Entity.CargoStatus;
import com.hilgo.Exercise_1.Entity.Driver;
import com.hilgo.Exercise_1.Entity.ShipmentsSent;
import com.hilgo.Exercise_1.Entity.User;
import com.hilgo.Exercise_1.repo.CargoRepository;
import com.hilgo.Exercise_1.repo.DriverRepository;
import com.hilgo.Exercise_1.repo.ShipmentsSentRepository;
import com.hilgo.Exercise_1.repo.UserRepository;
import com.hilgo.Exercise_1.request.DriverRequest;
import com.hilgo.Exercise_1.responses.CargoesResponse;
import com.hilgo.Exercise_1.responses.DriverResponse;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DriverService {
	
	final private UserRepository userRepository;
	final private CargoRepository cargoRepository;
	final private ShipmentsSentRepository shipmentsSentRepository;
	final private DriverRepository driverRepo;
	
	
	public boolean takeCargo(Long cargoId) {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		Optional<User> optUser = userRepository.findByUsername(username);
		if (optUser.isEmpty()) {
			throw new RuntimeException("User does not exist.");
		}
		Cargo cargo = cargoRepository.findById(cargoId).orElseThrow(() -> new RuntimeException("Cargo does not exist."));
		
		if (cargo.getDriver() != null) {
			throw new RuntimeException("Cargo has already been assigned to a driver.");
		}
		
		Driver driver = (Driver) optUser.get();
		
		cargo.setDriver(driver);
		cargo.setCargoStatus(CargoStatus.IN_PROGRESS);
		cargo.setDeliveryCode(generateDeliveryCode());
		cargo.setTakingTime(LocalDateTime.now());
		
		cargoRepository.save(cargo);
		
		
		return true;
	}

	public boolean deliverCargo(Long cargoId, Long deliveryCode) {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		Optional<User> optUser = userRepository.findByUsername(username);
		if (optUser.isEmpty()) {
			throw new RuntimeException("User does not exist.");
		}

		Cargo cargo = cargoRepository.findById(cargoId).orElseThrow(() -> new RuntimeException("Cargo does not exist."));
		    
		if (cargo.getDriver() == null) {
			throw new RuntimeException("Cargo has not been assigned to a driver.");
		}
		
		if (!cargo.getDeliveryCode().equals(deliveryCode)) {
	        throw new RuntimeException("Incorrect delivery code.");
	    }
		
		cargo.setCargoStatus(CargoStatus.DELIVERED);
		cargo.setDeliveredTime(LocalDateTime.now()); 
		cargoRepository.save(cargo);
		  
		ShipmentsSent shipment = new ShipmentsSent();
		shipment.setCargo(cargo);
		shipment.setDriver(cargo.getDriver());
		shipment.setDistributor(cargo.getDistributor());
		shipment.setDate(LocalDateTime.now());

		shipmentsSentRepository.save(shipment);
		
		return true;
	}
	
	
	
	private String generateDeliveryCode() {
		Random random = new Random();
		int code = random.nextInt(900000) + 100000;
		return String.valueOf(code);
	}

	public Page<CargoesResponse> getMyCargoes(Pageable pageable) {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		Optional<User> userOpt = userRepository.findByUsername(username);
		if(userOpt.isEmpty()) {
			throw new RuntimeException("User not found.");
		}
		Driver driver = (Driver) userOpt.get();
		
		Page<Cargo> cargoesPage = cargoRepository.findByDriverId(driver.getId(), pageable);
		Page<CargoesResponse> cargoResponse = cargoesPage.map(cargo -> new CargoesResponse(
				cargo.getCargoId(),
				cargo.getDescription(),
				cargo.getCargoSituation(), 
				cargo.getPhoneNumber()));
		return cargoResponse;
	}
	
	public DriverResponse updateDriver(DriverRequest driverRequest) {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		Optional<User> driverOpt = userRepository.findByUsername(username);
		if (driverOpt.isEmpty()) {
		    throw new RuntimeException("User Not Found");
		}
		if (!driverOpt.get().getUsername().equals(driverRequest.getUserName()) && userRepository.existsByUsername(driverRequest.getUserName())) {
			throw new RuntimeException("Username is already exist!");
		}
		if (!driverOpt.get().getMail().equals(driverRequest.getMail()) && userRepository.existsByMail(driverRequest.getMail())) {
			throw new RuntimeException("Mail is already exist!");
		}
		if (driverOpt.isPresent()) {
			User driver = driverOpt.get();
			((Driver)driver).setMail(driverRequest.getMail());
			((Driver)driver).setPhoneNumber(driverRequest.getPhoneNumber());
			((Driver)driver).setUsername(driverRequest.getUserName());
			((Driver)driver).setCarTypes(driverRequest.getCarTypes());
			driver.setId(driverOpt.get().getId());
			driver.setUsername(driverOpt.get().getUsername());
			userRepository.save(driver);
			
			return DriverResponse.builder()
					.Tc(((Driver)driver).getTc())
					.carTypes(((Driver)driver).getCarTypes())
					.phoneNumber(((Driver)driver).getPhoneNumber())
					.mail(driver.getMail())
					.build();
		}
		else {
			throw new RuntimeException("User Not Found");
		}
	}
	
	public Page<CargoesResponse> getAllCargoes(Pageable pageable) {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		Long id = userRepository.findByUsername(username).get().getId();
		Optional<Driver> driverOpt = driverRepo.findById(id);
		if (driverOpt.isEmpty()) {
			throw new RuntimeException("User Not Found");
		}
		Page<Cargo> cargoes = cargoRepository.findAll(pageable);
		Page<CargoesResponse> cargoResponse = cargoes.map(cargo -> new CargoesResponse(cargo.getCargoId(),cargo.getDescription(),cargo.getCargoSituation(), cargo.getPhoneNumber()));
		return cargoResponse;
	}

}
