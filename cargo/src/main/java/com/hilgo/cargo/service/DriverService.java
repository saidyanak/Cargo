package com.hilgo.cargo.service;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.Random;

<<<<<<< HEAD
=======
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
>>>>>>> 48d8eb7f47d7460a19a29f7b199df3a9bbaf84b2
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import com.hilgo.cargo.entity.Cargo;
import com.hilgo.cargo.entity.Driver;
import com.hilgo.cargo.entity.ShipmentSent;
import com.hilgo.cargo.entity.User;
import com.hilgo.cargo.entity.enums.CargoSituation;
<<<<<<< HEAD
import com.hilgo.cargo.repository.CargoRepository;
import com.hilgo.cargo.repository.ShipmentSendRepository;
import com.hilgo.cargo.repository.UserRepository;
import com.hilgo.cargo.request.DriverRequest;
import com.hilgo.cargo.response.CargoResponse;
import com.hilgo.cargo.response.DriverResponse;
=======
import com.hilgo.cargo.repository.CargoRespository;
import com.hilgo.cargo.repository.DriverRepository;
import com.hilgo.cargo.repository.ShipmentSendRepository;
import com.hilgo.cargo.repository.UserRepository;
import com.hilgo.cargo.request.DriverRequest;
import com.hilgo.cargo.response.CargoesResponse;
import com.hilgo.cargo.response.DriverResponse;
import com.hilgo.cargo.response.ResponseLocation;
import com.hilgo.cargo.response.ResponseMeasure;
>>>>>>> 48d8eb7f47d7460a19a29f7b199df3a9bbaf84b2

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DriverService {

<<<<<<< HEAD
	final private CargoRepository cargoRepository;
	final private UserRepository userRepository;
	final private ShipmentSendRepository shipmentSendRepository;
	
=======
	final private CargoRespository cargoRepository;
	final private UserRepository userRepository;
	final private ShipmentSendRepository shipmentSendRepository;
	final private DriverRepository driverRepository;

>>>>>>> 48d8eb7f47d7460a19a29f7b199df3a9bbaf84b2
	private String generateDeliveryCode() {
		Random random = new Random();
		int code = random.nextInt(900000) + 100000;
		return String.valueOf(code);
	}
<<<<<<< HEAD
	
	public CargoResponse takeCargo(Long cargoId) {
		Cargo cargo = cargoRepository.findById(cargoId)
				.orElseThrow(() -> new RuntimeException("Cargo not found"));
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		User user = userRepository.findByUsername(username)
				.orElseThrow(() -> new RuntimeException("User not found"));
		Driver driver = (Driver)user;
		cargo.setDriver(driver);
		cargo.setCargoSituation(CargoSituation.PICKED_UP);
		cargo.setVerificationCode(generateDeliveryCode());
		cargo.setTakingTime(LocalDateTime.now());
		cargoRepository.save(cargo);
		return CargoResponse.builder()
				.description(cargo.getDescription())
				.selfLocation(cargo.getSelfLocation())
				.targetLocation(cargo.getTargetLocation())
				.measure(cargo.getMeasure())
				.phoneNumber(cargo.getPhoneNumber())
				.cargoSituation(cargo.getCargoSituation())
				.build()
				;
=======

	public Boolean takeCargo(Long cargoId) {
		Cargo cargo = cargoRepository.findById(cargoId).orElseThrow(() -> new RuntimeException("Cargo not found"));
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		User user = userRepository.findByUsername(username).orElseThrow(() -> new RuntimeException("User not found"));
		Driver driver = (Driver) user;
		cargo.setDriver(driver);
		cargo.setCargoSituation(CargoSituation.PICKED_UP);
		cargo.setVerificationCode(generateDeliveryCode());
		cargo.setTakeingTime(LocalDateTime.now());
		cargoRepository.save(cargo);
		return true;
>>>>>>> 48d8eb7f47d7460a19a29f7b199df3a9bbaf84b2
	}

	public boolean deliverCargo(Long cargoId, String verificationCode) {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
<<<<<<< HEAD
		Driver driver = (Driver)userRepository.findByUsername(username).get();
=======
		Driver driver = (Driver) userRepository.findByUsername(username).get();
>>>>>>> 48d8eb7f47d7460a19a29f7b199df3a9bbaf84b2
		Cargo cargo = cargoRepository.findByIdAndDriverId(cargoId, driver.getId())
				.orElseThrow(() -> new RuntimeException("Cargo Not found"));
		if (!cargo.getVerificationCode().equals(verificationCode)) {
			throw new RuntimeException("Incorrect verification code");
		}
		cargo.setCargoSituation(CargoSituation.DELIVERED);
		cargo.setDeliveredTime(LocalDateTime.now());
		cargoRepository.save(cargo);
<<<<<<< HEAD
		
=======

>>>>>>> 48d8eb7f47d7460a19a29f7b199df3a9bbaf84b2
		ShipmentSent shipmentSent = new ShipmentSent();
		shipmentSent.setCargo(cargo);
		shipmentSent.setDriver(driver);
		shipmentSent.setDistributor(cargo.getDistributor());
		shipmentSent.setDate(LocalDateTime.now());
		shipmentSendRepository.save(shipmentSent);
		return true;
	}
<<<<<<< HEAD
	
	
=======

>>>>>>> 48d8eb7f47d7460a19a29f7b199df3a9bbaf84b2
	public DriverResponse updateDriver(DriverRequest driverRequest) {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		Optional<User> driverOpt = userRepository.findByUsername(username);
		if (driverOpt.isEmpty()) {
<<<<<<< HEAD
		    throw new RuntimeException("User Not Found");
		}
		if (!driverOpt.get().getUsername().equals(driverRequest.getUsername()) && userRepository.existsByUsername(driverRequest.getUsername())) {
			throw new RuntimeException("Username is already exist!");
		}
		if (!driverOpt.get().getMail().equals(driverRequest.getMail()) && userRepository.existsByMail(driverRequest.getMail())) {
			throw new RuntimeException("Mail is already exist!");
		}
		if (!driverOpt.get().getPhoneNumber().equals(driverRequest.getPhoneNumber()) && userRepository.existsByPhoneNumber(driverRequest.getPhoneNumber())) {
=======
			throw new RuntimeException("User Not Found");
		}
		if (!driverOpt.get().getUsername().equals(driverRequest.getUsername())
				&& userRepository.existsByUsername(driverRequest.getUsername())) {
			throw new RuntimeException("Username is already exist!");
		}
		if (!driverOpt.get().getMail().equals(driverRequest.getMail())
				&& userRepository.existsByMail(driverRequest.getMail())) {
			throw new RuntimeException("Mail is already exist!");
		}
		if (!driverOpt.get().getPhoneNumber().equals(driverRequest.getPhoneNumber())
				&& userRepository.existsByPhoneNumber(driverRequest.getPhoneNumber())) {
>>>>>>> 48d8eb7f47d7460a19a29f7b199df3a9bbaf84b2
			throw new RuntimeException("Phone Number is already exist!");
		}
		if (driverOpt.isPresent()) {
			User driver = driverOpt.get();
			driver.setMail(driverRequest.getMail());
			driver.setPhoneNumber(driverRequest.getPhoneNumber());
			driver.setUsername(driverRequest.getUsername());
<<<<<<< HEAD
			((Driver)driver).setCarType(driverRequest.getCarType());
			userRepository.save(driver);
			return DriverResponse.builder()
					.tc(((Driver)driver).getTc())
					.username(driver.getUsername())
					.carType(driverRequest.getCarType())
					.password(driver.getPassword())
					.phoneNumber(driver.getPhoneNumber())
					.mail(driver.getMail())
					.build();
		}
		else {
			throw new RuntimeException("User Not Found");
		}
	}
	
	
	
	
	
	
	
	
	
	
	
	
	
	
=======
			((Driver) driver).setCarType(driverRequest.getCarType());
			userRepository.save(driver);
			return DriverResponse.builder().tc(((Driver) driver).getTc()).username(driver.getUsername())
					.carType(driverRequest.getCarType()).password(driver.getPassword())
					.phoneNumber(driver.getPhoneNumber()).mail(driver.getMail()).build();
		} else {
			throw new RuntimeException("User Not Found");
		}
	}

	public Page<CargoesResponse> getMyCargoes(Pageable pageable) {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		Optional<User> userOpt = userRepository.findByUsername(username);
		if (userOpt.isEmpty()) {
			throw new RuntimeException("User not found.");
		}
		Driver driver = (Driver) userOpt.get();

		Page<Cargo> cargoesPage = cargoRepository.findByDriverId(driver.getId(), pageable);
		Page<CargoesResponse> cargoResponse = cargoesPage.map(cargo -> new CargoesResponse(cargo.getId(),
				new ResponseLocation(cargo.getTargetlocation().getLatitude(), cargo.getTargetlocation().getLongitude()),
				new ResponseLocation(cargo.getSelflocation().getLatitude(), cargo.getSelflocation().getLongitude()),
				new ResponseMeasure(cargo.getMeasure().getId(), cargo.getMeasure().getWeight(),
						cargo.getMeasure().getHeight()),
				cargo.getCargoSituation(), cargo.getPhoneNumber(), cargo.getDistributor().getPhoneNumber()));
		return cargoResponse;
	}

	public Page<CargoesResponse> getAllCargoes(Pageable pageable) {
		String username = SecurityContextHolder.getContext().getAuthentication().getName();
		Long id = userRepository.findByUsername(username).get().getId();
		Optional<Driver> driverOpt = driverRepository.findById(id);
		if (driverOpt.isEmpty()) {
			throw new RuntimeException("User Not Found");
		}
		Page<Cargo> cargoes = cargoRepository.findAll(pageable);
		Page<CargoesResponse> cargoResponse = cargoes.map(cargo -> new CargoesResponse(cargo.getId(),
				new ResponseLocation(cargo.getTargetlocation().getLatitude(), cargo.getTargetlocation().getLongitude()),
				new ResponseLocation(cargo.getSelflocation().getLatitude(), cargo.getSelflocation().getLongitude()),
				new ResponseMeasure(cargo.getMeasure().getId(), cargo.getMeasure().getWeight(),
						cargo.getMeasure().getHeight()),
				cargo.getCargoSituation(), cargo.getPhoneNumber(), cargo.getDistributor().getPhoneNumber()));
		return cargoResponse;
	}
>>>>>>> 48d8eb7f47d7460a19a29f7b199df3a9bbaf84b2
}
